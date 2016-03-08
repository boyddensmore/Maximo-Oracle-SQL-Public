/*******************************************************************************
*  Escalations on Closed tickets only.

*  Only count tickets open during month.
*******************************************************************************/

define STARTDATE = "'01-JUN-15 00:00:00'";
define ENDDATE = "'01-JUL-15 00:00:00'";

select distinct MAIN_TK.AFFECTEDPERSON, person.displayname, PERSON.TITLE, PERSON.EX_BUSINESSUNIT, PERSON.DEPARTMENT,
  (select count(*) TKCOUNT from ticket join worklog on WORKLOG.RECORDKEY = ticket.TICKETID 
      where ticket.status = 'CLOSED' and ticket.affectedperson = MAIN_TK.affectedperson 
      and ticket.ACTUALFINISH >= TO_DATE(&STARTDATE, 'dd-MON-yy hh24:mi:ss') 
      and ticket.ACTUALFINISH < TO_DATE(&ENDDATE, 'dd-MON-yy hh24:mi:ss') and logtype = 'ESCALATE') USERESCALATIONS,
      
  (select count(*) TKCOUNT from ticket 
      where ticket.status = 'CLOSED' and ticket.affectedperson = MAIN_TK.affectedperson 
      and ticket.ACTUALFINISH >= TO_DATE(&STARTDATE, 'dd-MON-yy hh24:mi:ss')
      and ticket.ACTUALFINISH < TO_DATE(&ENDDATE, 'dd-MON-yy hh24:mi:ss')
      -- Exclude double counts of SR/INC
      and (ticket.class = 'SR' or (ticket.class = 'INCIDENT' and ticket.Origrecordid is null))) TOTALTICKETSFORUSER
from TICKET MAIN_TK
  join person on person.personid = MAIN_TK.affectedperson
where MAIN_TK.ACTUALFINISH >= TO_DATE(&STARTDATE, 'dd-MON-yy hh24:mi:ss')
  and MAIN_TK.ACTUALFINISH < TO_DATE(&ENDDATE, 'dd-MON-yy hh24:mi:ss')
  and MAIN_TK.status = 'CLOSED'
  and MAIN_TK.TICKETID in (select recordkey from worklog where LOGTYPE = 'ESCALATE')
order by USERESCALATIONS desc;