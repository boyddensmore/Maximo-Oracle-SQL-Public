/*******************************************************************************
*  Run this first if you get an error saying the table or view can't be found.
*******************************************************************************/

ALTER SESSION SET CURRENT_SCHEMA = Maximo;


/*******************************************************************************
*  SD4 - Email Response Times
*  Just the numbers
*******************************************************************************/


-- Response Time Calculation with Dates
select (select count(*) from ticket,tkstatus 
        where ticket.ticketid = tkstatus.ticketid 
         and round(((tkstatus.changedate)-REPORTDATE)*24,1) <= 4.0
         and externalsystem = 'EMAIL'
         and tkstatus.changedate is not null 
         and reportdate is not null
         and reportdate between TO_DATE ('2016/02/01', 'yyyy/mm/dd') AND TO_DATE ('2016/02/29', 'yyyy/mm/dd')
         and tkstatus.TKSTATUSID in (select min(tkstatusid) from tkstatus where status = 'INPROG' group by ticketid)) as response_time_good,
       (select count(*) from ticket,tkstatus 
        where ticket.ticketid = tkstatus.ticketid 
         and externalsystem = 'EMAIL'
         --and tkstatus.changedate is not null 
         and reportdate is not null
         and reportdate between TO_DATE ('2016/02/01', 'yyyy/mm/dd') AND TO_DATE ('2016/02/29', 'yyyy/mm/dd')
         and tkstatus.TKSTATUSID in (select min(tkstatusid) from tkstatus where status = 'INPROG' group by ticketid)) as Total_Tickets,
      (round ((
       (select count(*) from ticket,tkstatus 
        where ticket.ticketid = tkstatus.ticketid 
         and round(((tkstatus.changedate)-REPORTDATE)*24,1) <= 4.0
         and externalsystem = 'EMAIL'
         and tkstatus.changedate is not null 
         and reportdate is not null
         and reportdate between TO_DATE ('2016/02/01', 'yyyy/mm/dd') AND TO_DATE ('2016/02/29', 'yyyy/mm/dd')
         and tkstatus.TKSTATUSID in (select min(tkstatusid) from tkstatus where status = 'INPROG' group by ticketid)) / 
       (select count(*) from ticket,tkstatus 
        where ticket.ticketid = tkstatus.ticketid 
         and externalsystem = 'EMAIL'
         and tkstatus.changedate is not null 
         and reportdate is not null 
         and reportdate between TO_DATE ('2016/02/01', 'yyyy/mm/dd') AND TO_DATE ('2016/02/29', 'yyyy/mm/dd')
         and tkstatus.TKSTATUSID in (select min(tkstatusid) from tkstatus where status = 'INPROG' group by ticketid)))*100,2)) as Perc_Responded_within_4_hours
from dual;



/*******************************************************************************
*  SD4 - Email Response Times
*  Full list of tickets for validation
*******************************************************************************/


SELECT 
  TICKETS.TICKETID,
  TICKETS.reportdate,
  tickets.actualstart,
  round((TICKETS.ACTUALSTART-TICKETS.REPORTDATE)*24,2) CAL_HRS_TO_RESPOND,
  case when (round((TICKETS.ACTUALSTART-TICKETS.REPORTDATE)*24,2) > 4.0) then 'BREACH' else 'MET' end SLA_MET,
  TICKETS.CLASS,
  CLASSPATH.CLASSPATH,
  ASSET.ASSETTAG,
  CI.CINAME,
  TICKETS.STATUS,
  TICKETS.CREATEDBY,
  TICKETS.OWNERGROUP, TICKETS.OWNER,
  TICKETS.INTERNALPRIORITY,
  NVL(TICKETS.EX_SUPPORTCALENDAR, 'BRONZE') EX_SUPPORTCALENDAR,
  TICKETS.EXVIP
FROM TICKET TICKETS
  join (select classstructureid, LISTAGG(ANCESTORCLASSID, ' \ ') within group (order by hierarchylevels desc) as CLASSPATH from CLASSANCESTOR group by classstructureid) CLASSPATH on CLASSPATH.CLASSstructureid = TICKETS.CLASSSTRUCTUREID
  left join ASSET on TICKETS.ASSETNUM = ASSET.ASSETNUM
  join classstructure on TICKETS.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
  left join CI on TICKETS.CINUM = CI.CINUM
WHERE 
  /* Ticket is not an SR with a FOLLOWUP Incident*/
  NOT EXISTS
  (
    SELECT RECORDKEY,
      RELATEDRECKEY
    FROM RELATEDRECORD
    WHERE CLASS           = 'SR'
      AND RELATEDRECCLASS = 'INCIDENT'
      AND RELATETYPE      = 'FOLLOWUP'
      AND RECORDKEY       = TICKETS.TICKETID
  )
  /* Ticket was logged by a member of the Service Desk*/
  and exists (select 1 from persongroupteam where persongroup = 'SERVICE DESK' and respparty = TICKETS.CREATEDBY)
  /* Ticket was responded to by a member of the Service Desk*/
  and exists (select 1
              from tkstatus
              where ownergroup = 'SERVICE DESK'
                and status = 'INPROG'
                and tkstatus.ticketid = tickets.ticketid)
  AND (TICKETS.EX_APPNAME != 'EX_SR' OR TICKETS.EX_APPNAME IS NULL)
  and TICKETS.EX_SITUATION is null
  and TICKETS.CLASS in ('SR', 'INCIDENT')
  and TICKETS.externalsystem = 'EMAIL'
/*Test Filters*/
  AND TICKETS.REPORTDATE >= to_date('18-SEP-2015 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
;