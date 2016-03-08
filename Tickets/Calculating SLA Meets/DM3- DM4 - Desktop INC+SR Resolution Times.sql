/*******************************************************************************
*  Run this first if you get an error saying the table or view can't be found.
*******************************************************************************/

ALTER SESSION SET CURRENT_SCHEMA = Maximo;

/*******************************************************************************
*  DM3/4 - Desktop INC/SR Resolution Times
*  Just the numbers
*******************************************************************************/

SELECT 
  TICKETS.CLASS,
  trunc(TICKETS.ACTUALFINISH, 'MON') ACTUAL_FINISH_MONTH,
  TICKETS.INTERNALPRIORITY,
  count(*) TOTAL,
  -- BUSDAYS_FROM_ASSIGN_TO_RESOLVE
  count(
    case when 
      ((TICKETS.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE)
      - (COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
          where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
              and (startdate <= tickets.ACTUALFINISH or enddate <= tickets.ACTUALFINISH)), 0) / 1440)
      - (COALESCE(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 0) / 1440)
      - case 
        -- If Support Calendar is Gold, or if customer is VIP, do not exclude weekend days
        when (TICKETS.EX_SUPPORTCALENDAR = 'GOLD' or TICKETS.EXVIP = 'VIP') then
              (
                0
              )
        -- If Support Calendar is Silver, exclude Sun
        when TICKETS.EX_SUPPORTCALENDAR = 'SILVER' then
              (
                SELECT count(*)
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (7)
                CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
              )
        -- If Support Calendar is Bronze, exclude Sat/Sun
        when NVL(TICKETS.EX_SUPPORTCALENDAR, 'BRONZE') = 'BRONZE' then
              (
                SELECT count(*)
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (6,7)
                CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
              )
      else null end 
      <=
      case 
        when TICKETS.INTERNALPRIORITY = 1 then (1/24)
        when TICKETS.INTERNALPRIORITY = 2 then (4/24)
        when TICKETS.INTERNALPRIORITY = 3 then (2)
        when TICKETS.INTERNALPRIORITY = 4 then (4)
      else 99999 end
        ) then 1 else null end) METCOUNT,
  round(count(
    case when 
      ((TICKETS.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE)
      - (COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
          where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
              and (startdate <= tickets.ACTUALFINISH or enddate <= tickets.ACTUALFINISH)), 0) / 1440)
      - (COALESCE(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 0) / 1440)
      - case 
        -- If Support Calendar is Bronze, or if customer is VIP, do not exclude weekend days
        when (TICKETS.EX_SUPPORTCALENDAR = 'GOLD' or TICKETS.EXVIP = 'VIP') then
              (
                0
              )
        -- If Support Calendar is Silver, exclude Sun
        when TICKETS.EX_SUPPORTCALENDAR = 'SILVER' then
              (
                SELECT count(*)
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (7)
                CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
              )
        -- If Support Calendar is Bronze, exclude Sat/Sun
        when NVL(TICKETS.EX_SUPPORTCALENDAR, 'BRONZE') = 'BRONZE' then
              (
                SELECT count(*)
                FROM DUAL
                WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (6,7)
                CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
              )
      else null end 
      <=
      case 
        when TICKETS.INTERNALPRIORITY = 1 then (1/24)
        when TICKETS.INTERNALPRIORITY = 2 then (4/24)
        when TICKETS.INTERNALPRIORITY = 3 then (2)
        when TICKETS.INTERNALPRIORITY = 4 then (4)
      else 99999 end
        ) then 1 else null end)
    / count(*) * 100, 2) METPCT
      
FROM TICKET TICKETS
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
  ((DESKSIDE_FIRST_OWNED.TKOWNERHISTORYID = (select min(TKOWNERHISTORYID) from TKOWNERHISTORY where ownergroup = 'DESKSIDE' and TICKETID = TICKETS.TICKETID))
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
  AND (TICKETS.EX_APPNAME != 'EX_SR' OR TICKETS.EX_APPNAME IS NULL)
  and TICKETS.INTERNALPRIORITY in (1, 2, 3, 4)
  and tickets.class = 'SR'
--Test Filters
  AND TICKETS.ACTUALFINISH >= SYSDATE - 30
group by TICKETS.CLASS, trunc(TICKETS.ACTUALFINISH, 'MON'), TICKETS.INTERNALPRIORITY
order by TICKETS.CLASS, trunc(TICKETS.ACTUALFINISH, 'MON'), TICKETS.INTERNALPRIORITY
;



/*******************************************************************************
*  DM3/4 - Desktop INC/SR Resolution Times
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
  COALESCE(round(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS / 1440, 4), 0) SLAHOLD_TOTAL_DAYS,
  /*Saturdays*/
  (SELECT count(*)
    FROM DUAL
    WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (6)
    CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
  ) Saturdays,
  /* Sundays*/
  (SELECT count(*)
    FROM DUAL
    WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (7)
    CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
  ) Sundays,
  /* Counted Weekend Days*/
  case 
    /* If Support Calendar is Gold, or if customer is VIP, do not exclude weekend days*/
    when (TICKETS.EX_SUPPORTCALENDAR = 'GOLD' or TICKETS.EXVIP = 'VIP') then
          (
            0
          )
    /* If Support Calendar is Silver, exclude Sun*/
    when TICKETS.EX_SUPPORTCALENDAR = 'SILVER' then
          (
            SELECT count(*)
            FROM DUAL
            WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (7)
            CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
          )
    /* If Support Calendar is Bronze, exclude Sat/Sun*/
    when NVL(TICKETS.EX_SUPPORTCALENDAR, 'BRONZE') = 'BRONZE' then
          (
            SELECT count(*)
            FROM DUAL
            WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (6,7)
            CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
          )
  else null end WEEKEND_DAYS_EXCLUDED,
  
/*  DSKOWN_RESOLVE_HOLIDAY_TIME*/
  COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
  where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
      and (startdate <= tickets.ACTUALFINISH or enddate <= tickets.ACTUALFINISH)) / 1440, 0) DSKOWN_RESOLVE_HOLIDAY_DAYS,
  TO_CHAR(TICKETS.ACTUALFINISH, 'yyyy-MM-dd hh24:mi:ss') ACTUALFINISH,
  round(TICKETS.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE, 2) CALDAYS_DELTA,
  /* BUSDAYS_FROM_ASSIGN_TO_RESOLVE*/
  round((TICKETS.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE)
  - (COALESCE((select (sum(enddate - startdate + 1) * 24 * 60) HOLIDAY_MINUTES from nonworktime
      where (startdate >= DESKSIDE_FIRST_OWNED.OWNDATE or enddate >= DESKSIDE_FIRST_OWNED.OWNDATE) 
          and (startdate <= tickets.ACTUALFINISH or enddate <= tickets.ACTUALFINISH)), 0) / 1440)
  - (COALESCE(SLAHOLD_TIME.SLAHOLD_TOTAL_MINS, 0) / 1440)
  - case 
    /* If Support Calendar is Bronze, or if customer is VIP, do not exclude weekend days*/
    when (TICKETS.EX_SUPPORTCALENDAR = 'GOLD' or TICKETS.EXVIP = 'VIP') then
          (
            0
          )
    /* If Support Calendar is Silver, exclude Sun*/
    when TICKETS.EX_SUPPORTCALENDAR = 'SILVER' then
          (
            SELECT count(*)
            FROM DUAL
            WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (7)
            CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
          )
    /* If Support Calendar is Bronze, exclude Sat/Sun*/
    when NVL(TICKETS.EX_SUPPORTCALENDAR, 'BRONZE') = 'BRONZE' then
          (
            SELECT count(*)
            FROM DUAL
            WHERE 1 + TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level) - TRUNC (DESKSIDE_FIRST_OWNED.OWNDATE + level, 'IW') in (6,7)
            CONNECT BY LEVEL <= tickets.ACTUALFINISH - DESKSIDE_FIRST_OWNED.OWNDATE
          )
  else null end, 2) BUSDAYS_FROM_ASSIGN_TO_RESOLVE
FROM TICKET TICKETS
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
  ((DESKSIDE_FIRST_OWNED.TKOWNERHISTORYID = (select min(TKOWNERHISTORYID) from TKOWNERHISTORY where ownergroup = 'DESKSIDE' and TICKETID = TICKETS.TICKETID))
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
  /*after being assigned there the first time*/
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
  and tickets.class = 'SR'
/*Test Filters*/
  AND TICKETS.ACTUALSTART >= to_date('18-SEP-2015 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
order by TICKETS.ticketid
;