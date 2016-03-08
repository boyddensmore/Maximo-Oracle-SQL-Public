/*******************************************************************************
*  Run this first if you get an error saying the table or view can't be found.
*******************************************************************************/

ALTER SESSION SET CURRENT_SCHEMA = Maximo;

/*******************************************************************************
*  DM5/DM6 - Hardware Delivery to ENMAX Users
*  Just the numbers
*******************************************************************************/

SELECT
  -- Month
  trunc(tickets.actualfinish, 'MON') MONTH_RESOLVED,
  -- Location (In Calgary or not) 
  case when exists (select locancestor.location from locancestor where locancestor.ancestor = 'CALGARY' and locancestor.location = tickets.location)
    then 'CALGARY' else 'NOT CALGARY' end LOCATION_IN_CALGARY,
  -- Total
  count(*) TOTAL,
  -- When location is in Calgary, count number of tickets resolved in 2 days or less
  -- from time ticket was first assigned to Deskside.
  -- When location is outside of Calgary, count number of tickets resolved in 5 days or less
  -- from time ticket was first assigned to Deskside.
  count(case when 
    -- Location is in Calgary
    (exists (select locancestor.location from locancestor where locancestor.ancestor = 'CALGARY' and locancestor.location = tickets.location)
    -- Calendar days between assignment and resolution
    and round((TICKETS.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE)
        -- Minus count of holidays
        - (COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
            where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
                and (startdate <= tickets.ACTUALFINISH or enddate <= tickets.ACTUALFINISH)), 0) / 1440)
        -- Minus SLA Hold time
        - (COALESCE(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 0) / 1440), 2) <= 2)
    then 'MET'
    -- Location is NOT in Calgary
    when (not exists (select locancestor.location from locancestor where locancestor.ancestor = 'CALGARY' and locancestor.location = tickets.location)
    -- Calendar days between assignment and resolution
    and round((TICKETS.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE)
        -- Minus count of holidays
        - (COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
            where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
                and (startdate <= tickets.ACTUALFINISH or enddate <= tickets.ACTUALFINISH)), 0) / 1440)
        -- Minus SLA Hold time
        - (COALESCE(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 0) / 1440)
        -- Minus weekend days
        - (SELECT count(*)
            FROM DUAL
            WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (6, 7)
            CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
          ), 2) <= 5)
    then 'MET'
    else null end) METCOUNT,
    -- Same calculations as above, but METCOUNT / TOTAL to give percentage
  round(count(case when 
    -- Location is in Calgary
    (exists (select locancestor.location from locancestor where locancestor.ancestor = 'CALGARY' and locancestor.location = tickets.location)
    -- Calendar days between assignment and resolution
    and round((TICKETS.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE)
        -- Minus count of holidays
        - (COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
            where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
                and (startdate <= tickets.ACTUALFINISH or enddate <= tickets.ACTUALFINISH)), 0) / 1440)
        -- Minus SLA Hold time
        - (COALESCE(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 0) / 1440)
        -- Minus weekend days
        - (SELECT count(*)
            FROM DUAL
            WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (6, 7)
            CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
          ), 2) <= 2)
    then 'MET'
    -- Location is NOT in Calgary
    when (not exists (select locancestor.location from locancestor where locancestor.ancestor = 'CALGARY' and locancestor.location = tickets.location)
    -- Calendar days between assignment and resolution
    and round((TICKETS.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE)
        -- Minus count of holidays
        - (COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
            where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
                and (startdate <= tickets.ACTUALFINISH or enddate <= tickets.ACTUALFINISH)), 0) / 1440)
        -- Minus SLA Hold time
        - (COALESCE(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 0) / 1440)
        -- Minus weekend days
        - (SELECT count(*)
            FROM DUAL
            WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (6, 7)
            CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
          ), 2) <= 5) 
    then 'MET'
    else null end) / count(*) * 100, 2) MET_PERCENT
FROM SR TICKETS
  join (select classstructureid, LISTAGG(ANCESTORCLASSID, ' \ ') within group (order by hierarchylevels desc) as CLASSPATH from CLASSANCESTOR group by classstructureid) CLASSPATH on CLASSPATH.CLASSstructureid = TICKETS.CLASSSTRUCTUREID
  left join ASSET on TICKETS.ASSETNUM = ASSET.ASSETNUM
  join classstructure on TICKETS.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
  
  left join CI on TICKETS.CINUM = CI.CINUM
  left join TKOWNERHISTORY DESKSIDE_FIRST_OWNED on DESKSIDE_FIRST_OWNED.TICKETID = TICKETS.TICKETID
  -- SLAHOLD Time
  left join
    (select ticketid,
      round(sum(
        (to_number(REGEXP_REPLACE(STATUSTRACKING,'(\\d*)(:)(\\d*)(:)(\\d*)','\\1')) * 60) 
        + 
        to_number(REGEXP_REPLACE(STATUSTRACKING,'(\\d*)(:)(\\d*)(:)(\\d*)','\\3')) 
        + 
        round(to_number(REGEXP_REPLACE(STATUSTRACKING,'(\\d*)(:)(\\d*)(:)(\\d*)','\\5')) / 60, 5) 
      )) SLAHOLD_TOTAL_MINS
    from TKSTATUS
    where STATUS = 'SLAHOLD'
      and ownergroup = 'DESKSIDE'
    group by ticketid) SLAHOLD_TIME on SLAHOLD_TIME.TICKETID = TICKETS.TICKETID
WHERE 
  -- Only show the first instance of a ticket being assigned to Deskside
  ((DESKSIDE_FIRST_OWNED.TKOWNERHISTORYID = (select min(TKOWNERHISTORYID) from TKOWNERHISTORY where ownergroup = 'DESKSIDE' /*and owner is not null*/ and TICKETID = TICKETS.TICKETID))
    or DESKSIDE_FIRST_OWNED.TKOWNERHISTORYID is null)
  -- Ticket is not an SR with a FOLLOWUP Incident
  AND NOT EXISTS
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
    WHERE OWNERGROUP NOT IN ('DESKSIDE')
      AND TKOWNERHISTORY.TICKETID = TICKETS.TICKETID
      and TKOWNERHISTORY.OWNDATE > DESKSIDE_FIRST_OWNED.OWNDATE
  )
  and TICKETS.externalsystem = 'PROCUREPORTAL'
  and TICKETS.externalsystem_ticketid is not null
--  and not exists (select locancestor.location from locancestor where locancestor.ancestor = 'CALGARY' and locancestor.location = tickets.location)
--Test Filters
  AND TICKETS.ACTUALFINISH >= SYSDATE - 120

group by trunc(tickets.actualfinish, 'MON'),
  case when exists (select locancestor.location from locancestor where locancestor.ancestor = 'CALGARY' and locancestor.location = tickets.location)
    then 'CALGARY' else 'NOT CALGARY' end
order by trunc(tickets.actualfinish, 'MON'),
  case when exists (select locancestor.location from locancestor where locancestor.ancestor = 'CALGARY' and locancestor.location = tickets.location)
    then 'CALGARY' else 'NOT CALGARY' end
;



/*******************************************************************************
*  DM5/DM6 - Hardware Delivery to ENMAX Users
*  Full list of tickets for validation
*******************************************************************************/

SELECT
  TICKETS.TICKETID,
  CLASSPATH.CLASSPATH,
  TICKETS.EXTERNALSYSTEM,
  TICKETS.CREATEDBY,
  ASSET.ASSETTAG,
  CI.CINAME,
  TICKETS.STATUS,
  TICKETS.location,
  case when exists (select locancestor.location from locancestor where locancestor.ancestor = 'CALGARY' and locancestor.location = tickets.location)
  then 'CALGARY' else 'NOT CALGARY' end LOCATION_IN_CALGARY,
  TICKETS.EXVIP,
  TICKETS.OWNERGROUP, TICKETS.OWNER,
  TICKETS.INTERNALPRIORITY,
  NVL(TICKETS.EX_SUPPORTCALENDAR, 'BRONZE'),
/*  TO_CHAR(TICKETS.CREATIONDATE, 'yyyy-MM-dd hh24:mi:ss') CREATIONDATE,*/
/*  TO_CHAR(TICKETS.REPORTDATE, 'yyyy-MM-dd hh24:mi:ss') REPORTDATE,*/
  TO_CHAR(DESKSIDE_FIRST_OWNED.OWNDATE, 'yyyy-MM-dd hh24:mi:ss') DESKSIDE_TECH_FIRST_OWN_DATE,
  COALESCE(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 0) SLAHOLD_TOTAL_MINS,
  (SELECT count(*)
    FROM DUAL
    WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (6, 7)
    CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
  ) Weekend_Days,
/*  DSKOWN_RESOLVE_HOLIDAY_TIME*/
  COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
  where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
      and (startdate <= tickets.ACTUALFINISH or enddate <= tickets.ACTUALFINISH)), 0) DSKOWN_RESOLVE_HOLIDAY_TIME,
  TO_CHAR(TICKETS.ACTUALFINISH, 'yyyy-MM-dd hh24:mi:ss') ACTUALFINISH,
  round((TICKETS.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE)
  - (COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
      where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
          and (startdate <= tickets.ACTUALFINISH or enddate <= tickets.ACTUALFINISH)), 0) / 1440)
  - (COALESCE(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 0) / 1440)
  - (SELECT count(*)
    FROM DUAL
    WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (6, 7)
    CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
    ), 2) BUSDAYS_FROM_ASSIGN_TO_RESOLVE
FROM SR TICKETS
  join (select classstructureid, LISTAGG(ANCESTORCLASSID, ' \ ') within group (order by hierarchylevels desc) as CLASSPATH from CLASSANCESTOR group by classstructureid) CLASSPATH on CLASSPATH.CLASSstructureid = TICKETS.CLASSSTRUCTUREID
  left join ASSET on TICKETS.ASSETNUM = ASSET.ASSETNUM
  join classstructure on TICKETS.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
  left join CI on TICKETS.CINUM = CI.CINUM
  left join TKOWNERHISTORY DESKSIDE_FIRST_OWNED on DESKSIDE_FIRST_OWNED.TICKETID = TICKETS.TICKETID
  /* SLAHOLD Time*/
  left join
    (select ticketid,
      round(sum(
        (to_number(REGEXP_REPLACE(STATUSTRACKING,'(\\d*)(:)(\\d*)(:)(\\d*)','\\1')) * 60) 
        + 
        to_number(REGEXP_REPLACE(STATUSTRACKING,'(\\d*)(:)(\\d*)(:)(\\d*)','\\3')) 
        + 
        round(to_number(REGEXP_REPLACE(STATUSTRACKING,'(\\d*)(:)(\\d*)(:)(\\d*)','\\5')) / 60, 5) 
      )) SLAHOLD_TOTAL_MINS
    from TKSTATUS
    where STATUS = 'SLAHOLD'
      and ownergroup = 'DESKSIDE'
    group by ticketid) SLAHOLD_TIME on SLAHOLD_TIME.TICKETID = TICKETS.TICKETID
WHERE 
  /* Only show the first instance of a ticket being assigned to Deskside*/
  ((DESKSIDE_FIRST_OWNED.TKOWNERHISTORYID = (select min(TKOWNERHISTORYID) from TKOWNERHISTORY where ownergroup = 'DESKSIDE' /*and owner is not null*/ and TICKETID = TICKETS.TICKETID))
    or DESKSIDE_FIRST_OWNED.TKOWNERHISTORYID is null)
  /* Ticket is not an SR with a FOLLOWUP Incident*/
  AND NOT EXISTS
  (
    SELECT RECORDKEY,
      RELATEDRECKEY
    FROM RELATEDRECORD
    WHERE CLASS           = 'SR'
      AND RELATEDRECCLASS = 'INCIDENT'
      AND RELATETYPE      = 'FOLLOWUP'
      AND RECORDKEY       = TICKETS.TICKETID
  )
  /* Ticket has never been assigned to a group other than Deskside, */
  /* after being assigned there the first time*/
  AND NOT EXISTS
  (
    SELECT 1
    FROM TKOWNERHISTORY
    WHERE OWNERGROUP NOT IN ('DESKSIDE')
      AND TKOWNERHISTORY.TICKETID = TICKETS.TICKETID
      and TKOWNERHISTORY.OWNDATE > DESKSIDE_FIRST_OWNED.OWNDATE
  )
  AND (TICKETS.EX_APPNAME != 'EX_SR' OR TICKETS.EX_APPNAME IS NULL)
  and TICKETS.externalsystem = 'PROCUREPORTAL'
  and TICKETS.externalsystem_ticketid is not null
/*Test Filters*/
  AND TICKETS.ACTUALFINISH >= to_date('18-SEP-2015 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
order by TICKETS.ticketid
;
