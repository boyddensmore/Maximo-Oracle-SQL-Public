/*******************************************************************************
*  Run this first if you get an error saying the table or view can't be found.
*******************************************************************************/

ALTER SESSION SET CURRENT_SCHEMA = Maximo;


/*******************************************************************************
*  DM1/2 - Desktop INC/SR Response Times
*  Just the numbers
*******************************************************************************/


SELECT 
  TICKETS.CLASS,
  trunc(TICKETS.ACTUALSTART, 'MON') ACTUAL_START_MONTH,
  TICKETS.INTERNALPRIORITY,
  count(*) TOTAL,
  -- BUSDAYS_FROM_ASSIGN_TO_RESPONSE
  count(
    case when 
      (((TICKETS.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE) * 1440)
      - (COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
          where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
              and (startdate <= tickets.ACTUALSTART or enddate <= tickets.ACTUALSTART)), 0))
      - (COALESCE(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 0))
      -- Subtract Weekend days
      - case 
        when trunc(tickets.ACTUALSTART) = trunc(DESKSIDE_FIRST_OWNED.OWNDATE) then 0
        when (TICKETS.EX_SUPPORTCALENDAR = 'GOLD' or TICKETS.EXVIP = 'VIP') then
              -- If Support Calendar is Gold, or if customer is VIP, do not exclude weekend days
              (
                0
              )
        when TICKETS.EX_SUPPORTCALENDAR = 'SILVER' then
              -- If Support Calendar is Silver, exclude Sun
              (
                SELECT count(*) * 1440
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (7)
                CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
              )
              +
              -- Exclude beginning and end of days
              (
                SELECT (count(*) * 8) * 60
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (1,2,3,4,5,6)
                CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
              )
        when NVL(TICKETS.EX_SUPPORTCALENDAR, 'BRONZE') = 'BRONZE' then
              -- If Support Calendar is Bronze, exclude Sat/Sun
              (
                SELECT count(*) * 1440
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (6,7)
                CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
              )
              +
              -- Exclude beginning and end of days
              (
                SELECT (count(*) * 15) * 60
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (1,2,3,4,5)
                CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
              )
      else null end 
      <=
      -- Targets
      case 
        when TICKETS.INTERNALPRIORITY = 1 then 30 --(0.5/24)
        when TICKETS.INTERNALPRIORITY = 2 then 60 --(1/24)
        when TICKETS.INTERNALPRIORITY = 3 then 240 --(4/24)
        when TICKETS.INTERNALPRIORITY = 4 then 240 --(4/24)
      else 99999 end
        ) then 1 else null end) METCOUNT,
  round(count(
    case when 
      (((TICKETS.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE) * 1440)
      - (COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
          where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
              and (startdate <= tickets.ACTUALSTART or enddate <= tickets.ACTUALSTART)), 0))
      - (COALESCE(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 0))
      - case 
        when trunc(tickets.ACTUALSTART) = trunc(DESKSIDE_FIRST_OWNED.OWNDATE) then 0
        when (TICKETS.EX_SUPPORTCALENDAR = 'GOLD' or TICKETS.EXVIP = 'VIP') then
              -- If Support Calendar is Bronze, or if customer is VIP, do not exclude weekend days
              (
                0
              )
        when TICKETS.EX_SUPPORTCALENDAR = 'SILVER' then
              -- If Support Calendar is Silver, exclude Sun
              (
                SELECT count(*) * 1440
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (7)
                CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
              )
              +
              -- Exclude beginning and end of days
              (
                SELECT (count(*) * 8) * 60
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (1,2,3,4,5,6)
                CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
              )
        when NVL(TICKETS.EX_SUPPORTCALENDAR, 'BRONZE') = 'BRONZE' then
              -- If Support Calendar is Bronze, exclude Sat/Sun, beginning and end of days
              (
                SELECT count(*) * 1440
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (6,7)
                CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
              )
              +
              -- Exclude beginning and end of days
              (
                SELECT (count(*) * 15) * 60
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (1,2,3,4,5)
                CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
              )
      else null end 
      <=
      -- Targets
      case 
        when TICKETS.INTERNALPRIORITY = 1 then 30 --(0.5/24)
        when TICKETS.INTERNALPRIORITY = 2 then 60 --(1/24)
        when TICKETS.INTERNALPRIORITY = 3 then 240 --(4/24)
        when TICKETS.INTERNALPRIORITY = 4 then 240 --(4/24)
      else 99999 end
        ) then 1 else null end)
    / count(*) * 100, 2) METPCT
FROM MAXIMO.TICKET TICKETS
  join (select classstructureid, LISTAGG(ANCESTORCLASSID, ' \ ') within group (order by hierarchylevels desc) as CLASSPATH from MAXIMO.CLASSANCESTOR group by classstructureid) CLASSPATH on CLASSPATH.CLASSstructureid = TICKETS.CLASSSTRUCTUREID
  left join MAXIMO.ASSET on TICKETS.ASSETNUM = ASSET.ASSETNUM
  join MAXIMO.classstructure on TICKETS.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
  left join MAXIMO.CI on TICKETS.CINUM = CI.CINUM
  left join MAXIMO.TKOWNERHISTORY DESKSIDE_FIRST_OWNED on DESKSIDE_FIRST_OWNED.TICKETID = TICKETS.TICKETID
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
    from MAXIMO.TKSTATUS
    where STATUS = 'SLAHOLD'
      and ownergroup = 'DESKSIDE'
    group by ticketid) SLAHOLD_TIME on SLAHOLD_TIME.TICKETID = TICKETS.TICKETID
WHERE 
  -- Only show the first instance of a ticket being assigned to Deskside
  ((DESKSIDE_FIRST_OWNED.TKOWNERHISTORYID = (select min(TKOWNERHISTORYID) from MAXIMO.TKOWNERHISTORY where ownergroup = 'DESKSIDE' and TICKETID = TICKETS.TICKETID))
    or DESKSIDE_FIRST_OWNED.TKOWNERHISTORYID is null)
  -- Ticket is not an SR with a FOLLOWUP Incident
  AND NOT EXISTS
  (
    SELECT RECORDKEY,
      RELATEDRECKEY
    FROM MAXIMO.RELATEDRECORD
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
    FROM MAXIMO.TKOWNERHISTORY
    WHERE OWNERGROUP NOT IN ('DESKSIDE')
      AND TKOWNERHISTORY.TICKETID = TICKETS.TICKETID
      and TKOWNERHISTORY.OWNDATE > DESKSIDE_FIRST_OWNED.OWNDATE
  )
  AND (TICKETS.EX_APPNAME != 'EX_SR' OR TICKETS.EX_APPNAME IS NULL)
  and TICKETS.INTERNALPRIORITY in (1, 2, 3, 4)
--Test Filters
  AND TICKETS.ACTUALSTART >= SYSDATE - 60
group by TICKETS.CLASS, trunc(TICKETS.ACTUALSTART, 'MON'), TICKETS.INTERNALPRIORITY
order by TICKETS.CLASS, trunc(TICKETS.ACTUALSTART, 'MON'), TICKETS.INTERNALPRIORITY
;


/*******************************************************************************
*  DM1/2 - Desktop INC/SR Response Times
*  Full list of tickets for validation
*******************************************************************************/

SELECT 
  TICKETS.TICKETID,
  TICKETS.CLASS,
  CLASSPATH.CLASSPATH,
  ASSET.ASSETTAG,
  CI.CINAME,
  TICKETS.STATUS,
  TICKETS.OWNERGROUP, TICKETS.OWNER,
  TICKETS.INTERNALPRIORITY,
  NVL(TICKETS.EX_SUPPORTCALENDAR, 'BRONZE') EX_SUPPORTCALENDAR,
  TICKETS.EXVIP,
  TO_CHAR(DESKSIDE_FIRST_OWNED.OWNDATE, 'yyyy-MM-dd hh24:mi:ss') DESKSIDE_FIRST_OWN_DATE,
  COALESCE(round(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 4), 0) SLAHOLD_TOTAL_MINS,
  /* Saturdays */
  (SELECT count(*) * 1440
    FROM DUAL
    WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (6)
    CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
  ) Saturdays,
  /* Sundays */
  (SELECT count(*) * 1440
    FROM DUAL
    WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (7)
    CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
  ) Sundays,
  /* Counted Weekend Days */
  case
    when trunc(tickets.ACTUALSTART) = trunc(DESKSIDE_FIRST_OWNED.OWNDATE) then 0
    when (TICKETS.EX_SUPPORTCALENDAR = 'GOLD' or TICKETS.EXVIP = 'VIP') then
          /* If Support Calendar is Gold, or if customer is VIP, do not exclude weekend days */
          (
            0
          )
    when TICKETS.EX_SUPPORTCALENDAR = 'SILVER' then
          /* If Support Calendar is Silver, exclude Sun*/
              (
                SELECT count(*) * 1440
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (7)
                CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
              )
              +
              /* Exclude beginning and end of days */
              (
                SELECT (count(*) * 8) * 60
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (1,2,3,4,5,6)
                CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE
              )
    when NVL(TICKETS.EX_SUPPORTCALENDAR, 'BRONZE') = 'BRONZE' then
          /*If Support Calendar is Bronze, exclude Sat/Sun, beginning and end of days */
              (
                SELECT count(*) * 1440
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (6,7)
                CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
              )
              +
              /* Exclude beginning and end of days */
              (
                SELECT (count(*) * 15) * 60
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (1,2,3,4,5)
                CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE
              )
  else null end WEEKEND_DAYS_EXCLUDED,
/*  DSKOWN_RESPONSE_HOLIDAY_TIME */
  COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
  where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
      and (startdate <= tickets.ACTUALSTART or enddate <= tickets.ACTUALSTART)), 0) HOLIDAY_DAYS,
  TO_CHAR(TICKETS.ACTUALSTART, 'yyyy-MM-dd hh24:mi:ss') ACTUALSTART,
  round((TICKETS.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE) * 1440, 2) CALDAYS_DELTA,
  /* BUSDAYS_FROM_ASSIGN_TO_RESPONSE */
  round((TICKETS.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE) * 1440
  - (COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
      where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
          and (startdate <= tickets.ACTUALSTART or enddate <= tickets.ACTUALSTART)), 0))
  - (COALESCE(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 0))
  - case 
    when trunc(tickets.ACTUALSTART) = trunc(DESKSIDE_FIRST_OWNED.OWNDATE) then 0
    when (TICKETS.EX_SUPPORTCALENDAR = 'GOLD' or TICKETS.EXVIP = 'VIP') then
          /* If Support Calendar is Gold, or if customer is VIP, do not exclude weekend days */
          (
            0
          )
    when TICKETS.EX_SUPPORTCALENDAR = 'SILVER' then
          /* If Support Calendar is Silver, exclude Sun */
          (
            SELECT count(*) * 1440
            FROM DUAL
            WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (7)
            CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
          )
          +
          /* Exclude beginning and end of days */
          (
            SELECT (count(*) * 8) * 60
            FROM DUAL
            WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (1,2,3,4,5,6)
            CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE
          )
    when NVL(TICKETS.EX_SUPPORTCALENDAR, 'BRONZE') = 'BRONZE' then
          /* If Support Calendar is Bronze, exclude Sat/Sun, beginning and end of days */
          (
            SELECT count(*) * 1440
            FROM DUAL
            WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level-1, 'IW') in (6,7)
            CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE + 1
          )
          +
          /* Exclude beginning and end of days */
          (
            SELECT (count(*) * 15) * 60
            FROM DUAL
            WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (1,2,3,4,5)
            CONNECT BY LEVEL <= tickets.ACTUALSTART - DESKSIDE_FIRST_OWNED.OWNDATE
          )
  else null end, 2) BUSMINS,
  case 
    when TICKETS.INTERNALPRIORITY = 1 then 30 /*(0.5/24)*/
    when TICKETS.INTERNALPRIORITY = 2 then 60 /*(1/24)*/
    when TICKETS.INTERNALPRIORITY = 3 then 240 /*(4/24)*/
    when TICKETS.INTERNALPRIORITY = 4 then 240 /*(4/24)*/
  else 99999 end TARGET
FROM TICKET TICKETS
  join (select classstructureid, LISTAGG(ANCESTORCLASSID, ' \ ') within group (order by hierarchylevels desc) as CLASSPATH from CLASSANCESTOR group by classstructureid) CLASSPATH on CLASSPATH.CLASSstructureid = TICKETS.CLASSSTRUCTUREID
  left join ASSET on TICKETS.ASSETNUM = ASSET.ASSETNUM
  join classstructure on TICKETS.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
  left join CI on TICKETS.CINUM = CI.CINUM
  left join TKOWNERHISTORY DESKSIDE_FIRST_OWNED on DESKSIDE_FIRST_OWNED.TICKETID = TICKETS.TICKETID
  /* SLAHOLD Time */
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
  /* Only show the first instance of a ticket being assigned to Deskside */
  ((DESKSIDE_FIRST_OWNED.TKOWNERHISTORYID = (select min(TKOWNERHISTORYID) from TKOWNERHISTORY where ownergroup = 'DESKSIDE' and TICKETID = TICKETS.TICKETID))
    or DESKSIDE_FIRST_OWNED.TKOWNERHISTORYID is null)
  /* Ticket is not an SR with a FOLLOWUP Incident */
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
  /* after being assigned there the first time */
  AND NOT EXISTS
  (
    SELECT 1
    FROM TKOWNERHISTORY
    WHERE OWNERGROUP NOT IN ('DESKSIDE')
      AND TKOWNERHISTORY.TICKETID = TICKETS.TICKETID
      and TKOWNERHISTORY.OWNDATE > DESKSIDE_FIRST_OWNED.OWNDATE
  )
  AND (TICKETS.EX_APPNAME != 'EX_SR' OR TICKETS.EX_APPNAME IS NULL)
  and TICKETS.INTERNALPRIORITY in (1, 2, 3, 4)
/*Test Filters*/
  AND TICKETS.ACTUALSTART >= to_date('18-SEP-2015 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
order by TICKETS.ticketid
;