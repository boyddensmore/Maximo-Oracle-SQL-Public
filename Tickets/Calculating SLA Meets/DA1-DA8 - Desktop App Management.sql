/*******************************************************************************
*  Run this first if you get an error saying the table or view can't be found.
*******************************************************************************/

ALTER SESSION SET CURRENT_SCHEMA = Maximo;

/*******************************************************************************
*  DA1-DA8 - Desktop App Management
*  Number of tickets in APP-PKGING queue is small, Dax will review tickets
*  manually each month.
*  
*  This query returns any ticket which has been assigned to the APP-PKGING
*  queue and was open during any point last month.
*******************************************************************************/

select ticket.TICKETID, ticket.INTERNALPRIORITY, 
  ticket.AFFECTEDPERSON, ticket.REPORTEDBY, REPORTEDPERSON.STATUS RPT_PRSN_STAT,
  OWNER, ticket.STATUS, ticket.REPORTDATE, TICKET.ACTUALFINISH, ticket.DESCRIPTION summary,
  LONGDESCRIPTION.LDOWNERTABLE, LONGDESCRIPTION.LDOWNERCOL,
  REGEXP_REPLACE(LONGDESCRIPTION.LDTEXT,'<[^>]*>',' ') LONGDESCRIPTION
from ticket
  left join LONGDESCRIPTION on (LONGDESCRIPTION.LDKEY = ticket.TICKETUID 
                                and LONGDESCRIPTION.LDOWNERTABLE = 'TICKET' 
                                and LONGDESCRIPTION.LDOWNERCOL = 'DESCRIPTION'
                                )
  left join person AFFECTEDPERSON on AFFECTEDPERSON.PERSONID = ticket.AFFECTEDPERSON
  left join person REPORTEDPERSON on REPORTEDPERSON.PERSONID = ticket.REPORTEDBY
where ticket.class in ('SR', 'INCIDENT')
  and not exists (select 1
                  from RELATEDRECORD
                  where class = 'SR' and RELATEDRECCLASS = 'INCIDENT' and relatetype = 'FOLLOWUP'
                    and relatedrecord.recordkey = ticket.ticketid)
  /* Ticket has been assigned to App Packaging team */
  and exists (select 1
              from TKOWNERHISTORY
              where ownergroup = 'APP-PKGING'
                and TKOWNERHISTORY.TICKETID = TICKET.TICKETID)
  /* Ticket was open at some point during the previous month */
  and exists (select 1
              from ticket TK
                join
                  (select rownum - 1 + trunc(add_months(sysdate, -1), 'MON') DAY
                  from all_objects
                  where rownum < (trunc(add_months(sysdate, 0), 'MON')-1) -
                                 trunc(add_months(sysdate, -1), 'MON') + 2) DATE_LIST 
                on 
                  (DATE_LIST.DAY >= trunc(TK.reportdate)
                  and (DATE_LIST.DAY <= trunc(TK.actualfinish)
                    or (TK.actualfinish is null and DATE_LIST.DAY <= trunc(sysdate, 'MON'))))
              where 1=1
                and TK.ticketid = ticket.ticketid)
;