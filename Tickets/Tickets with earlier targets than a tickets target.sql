
/*******************************************************************************
*  For a given ticket, show other tickets in that team's queue with an
*  adjustedtargetfinish earlier than the ticket in question.
*******************************************************************************/

define TKID = "'IN-11239'";

select 
--  ticketid, ownergroup, owner, status, reportdate, ADJUSTEDTARGETRESOLUTIONTIME
  ownergroup, class, status, count(*)
from ticket
where ADJUSTEDTARGETRESOLUTIONTIME <= (select ADJUSTEDTARGETRESOLUTIONTIME from ticket where ticketid = &TKID)
  and ownergroup = (select ownergroup from ticket where ticketid = &TKID)
  and status not in ('CLOSED', 'RESOLVED')
  --  Exclude SRs with FOLLOWUP related incidents
  AND NOT EXISTS
  (
    SELECT RECORDKEY,
      RELATEDRECKEY
    FROM RELATEDRECORD
    WHERE CLASS           = 'SR'
      AND RELATEDRECCLASS = 'INCIDENT'
      AND RELATETYPE      = 'FOLLOWUP'
      AND RECORDKEY       = TICKET.TICKETID
  )
group by rollup(ownergroup, class, status)
order by ownergroup, class, status;

select personid from person where supervisor = 'CACKERMA';