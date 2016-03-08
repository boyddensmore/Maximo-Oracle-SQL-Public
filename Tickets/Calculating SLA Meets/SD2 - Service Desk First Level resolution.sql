/*******************************************************************************
*  Run this first if you get an error saying the table or view can't be found.
*******************************************************************************/

ALTER SESSION SET CURRENT_SCHEMA = Maximo;


/*******************************************************************************
*  SD2 - First Call Resolution
*  Just the numbers
*******************************************************************************/

SELECT
  TICKETS.CLASS,
  trunc(TICKETS.REPORTDATE, 'MON') REPORTED_MONTH,
  TICKETS.INTERNALPRIORITY,
  count(*) TOTAL
FROM TICKET TICKETS
  join (select classstructureid, LISTAGG(ANCESTORCLASSID, ' \ ') within group (order by hierarchylevels desc) as CLASSPATH from CLASSANCESTOR group by classstructureid) CLASSPATH on CLASSPATH.CLASSstructureid = TICKETS.CLASSSTRUCTUREID
  left join ASSET on TICKETS.ASSETNUM = ASSET.ASSETNUM
  join classstructure on TICKETS.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
  left join CI on TICKETS.CINUM = CI.CINUM
WHERE 
  -- Ticket is not an SR with a FOLLOWUP Incident
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
  -- Ticket has never been assigned to a group other than Deskside, 
  -- after being assigned there the first time
  AND NOT EXISTS
  (
    SELECT 1
    FROM TKOWNERHISTORY
    WHERE OWNERGROUP NOT IN ('SERVICE DESK')
      AND TKOWNERHISTORY.TICKETID = TICKETS.TICKETID
  )
  -- Ticket was logged by a member of the Service Desk
  and exists (select 1 from persongroupteam where persongroup = 'SERVICE DESK' and respparty = TICKETS.CREATEDBY)
  -- Ticket was resolved by a member of the Service Desk
  and exists (select 1 from persongroupteam where persongroup = 'SERVICE DESK' and respparty = TICKETS.OWNER)
  AND (TICKETS.EX_APPNAME != 'EX_SR' OR TICKETS.EX_APPNAME IS NULL)
  and TICKETS.INTERNALPRIORITY in (1, 2, 3, 4)
  and TICKETS.EX_SITUATION is null
  and TICKETS.CLASS in ('SR', 'INCIDENT')
--Test Filters
  AND TICKETS.REPORTDATE >= SYSDATE - 60
group by TICKETS.CLASS, trunc(TICKETS.REPORTDATE, 'MON'), TICKETS.INTERNALPRIORITY
order by TICKETS.CLASS, trunc(TICKETS.REPORTDATE, 'MON'), TICKETS.INTERNALPRIORITY
;



/*******************************************************************************
*  SD2 - First Call Resolution
*  Full list of tickets for validation
*******************************************************************************/

SELECT 
  TICKETS.TICKETID,
  TICKETS.CREATIONDATE,
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
  /* Ticket is not an SR with a FOLLOWUP Incident */
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
  /* Ticket has never been assigned to a group other than Service Desk, */
  /* after being assigned there the first time*/
  AND NOT EXISTS
  (
    SELECT 1
    FROM TKOWNERHISTORY
    WHERE OWNERGROUP NOT IN ('SERVICE DESK')
      AND TKOWNERHISTORY.TICKETID = TICKETS.TICKETID
  )
  /* Ticket was logged by a member of the Service Desk*/
  and exists (select 1 from persongroupteam where persongroup = 'SERVICE DESK' and respparty = TICKETS.CREATEDBY)
  /* Ticket was resolved by a member of the Service Desk*/
  and exists (select 1 from persongroupteam where persongroup = 'SERVICE DESK' and respparty = TICKETS.OWNER)
  AND (TICKETS.EX_APPNAME != 'EX_SR' OR TICKETS.EX_APPNAME IS NULL)
  and TICKETS.EX_SITUATION is null
  and TICKETS.CLASS in ('SR', 'INCIDENT')
/*Test Filters*/
  AND TICKETS.REPORTDATE >= to_date('18-SEP-2015 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
;

