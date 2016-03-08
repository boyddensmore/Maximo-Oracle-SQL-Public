/*******************************************************************************
*  Find a string in a Ticket's description(s)
*******************************************************************************/

select TICKET.TICKETID, TICKET.AFFECTEDPERSON, TICKET.REPORTEDBY, CI.CINAME, TICKET.OWNER, TICKET.OWNERGROUP, TICKET.DESCRIPTION, REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' ') LONG_DESCRIPTION
from TICKET
  join LONGDESCRIPTION on LONGDESCRIPTION.LDKEY = TICKET.TICKETUID
  left join ci on TICKET.CINUM = CI.CINUM
where LONGDESCRIPTION.LDOWNERCOL = 'DESCRIPTION' 
  and LONGDESCRIPTION.LDOWNERTABLE = 'TICKET'
  and TICKET.REPORTDATE >= trunc(sysdate, 'YY')
  and TICKET.TICKETID not in (select RELATEDRECKEY from RELATEDRECORD where RELATETYPE = 'ORIGINATOR' and class = 'INCIDENT' and RELATEDRECCLASS = 'SR')
--  and TICKET.OWNER in ('LMIC', 'FYANG')
  and (upper(TICKET.DESCRIPTION) like '%ZAI%'
    or upper(Longdescription.Ldtext) like '%ZAI%')
  and (CI.CINAME not in ('ZAINET - PROD') or CI.CINAME is null)
  and TICKET.CLASS in ('SR', 'INCIDENT')
;