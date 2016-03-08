
/*******************************************************************************
*  Details of offending tickets
*******************************************************************************/

SELECT 
  TICKETID,
  ',=' || TICKETID,
  EX_APPNAME,
  EXUPDATED,
  STATUS,
  CREATEDBY,
  OWNERGROUP,
  OWNER,
--  TO_CHAR(REPORTDATE, 'dd-MON-yy hh24:mi:ss') REPORTDATE,
--  TO_CHAR(REPORTDATE, 'HH24') REPORTHOUR,
--  TO_CHAR(REPORTDATE, 'DAY') REPORTDOW,
  INTERNALPRIORITY,
  EX_SUPPORTCALENDAR,
  TO_CHAR(TARGETFINISH, 'dd-MON-yy hh24:mi:ss') TARGETFINISH,
  TO_CHAR(ADJUSTEDTARGETRESOLUTIONTIME, 'dd-MON-yy hh24:mi:ss') ADJUSTEDTARGETRESOLUTIONTIME,
  SLARECORDS.SLANUM,
  TO_CHAR(SLARECORDS.RESOLUTIONDATE, 'dd-MON-yy hh24:mi:ss') RESOLUTIONDATE
--  count(*)
FROM sr
  LEFT JOIN SLARECORDS ON TICKETUID = SLARECORDS.OWNERID
WHERE (INTERNALPRIORITY != 5 or INTERNALPRIORITY is null)
  AND ADJUSTEDTARGETRESOLUTIONTIME IS NULL
  and SLARECORDS.SLANUM is null
  and (EX_APPNAME != 'EX_SR' or EX_APPNAME is null)
  AND REPORTDATE                   >= TO_DATE('21-OCT-15 00:00:00', 'dd-MON-yy hh24:mi:ss')
--  AND REPORTDATE                   <= TO_DATE('28-OCT-15 00:00:00', 'dd-MON-yy hh24:mi:ss')
  AND STATUS NOT                   IN ('CLOSED', 'NEW')
--  and (TO_CHAR(REPORTDATE, 'HH24') > '07'
--  and TO_CHAR(REPORTDATE, 'HH24') < '17')
--  and (TO_CHAR(REPORTDATE, 'HH24') <= '07'
--    or TO_CHAR(REPORTDATE, 'HH24') >= '17')
--  and TO_CHAR(REPORTDATE, 'DAY') not in ('SATURDAY', 'SUNDAY')
--  and SITEID = 'IT-IS'
--  and ticketid = 'IN-7705'
--  and INTERNALPRIORITY = 1
--  and EXUPDATED = 0
order by REPORTDATE desc
;



/*******************************************************************************
*  Number/percentage of not-null adjustedtargetresolutiontime on SR
*******************************************************************************/

select 
  class,
  count(*) TOTAL,
  count(case when (ADJUSTEDTARGETRESOLUTIONTIME is not null) then 1 else null end) ATRT_NOTNULL,
  count(case when (ADJUSTEDTARGETRESOLUTIONTIME is null) then 1 else null end) ATRT_NULL,
  count(case when (slanum is null) then 1 else null end) SLANUM_NULL,
  round(count(case when (ADJUSTEDTARGETRESOLUTIONTIME is not null) then 1 else null end) / count(*), 4) * 100 ATRT_NOTNULL_PCT
from ticket
  left join SLARECORDS on ownerid = ticketuid
where (INTERNALPRIORITY != 5 or INTERNALPRIORITY is null)
  AND REPORTDATE >= TO_DATE('20-OCT-15 00:00:00', 'dd-MON-yy hh24:mi:ss')
  and (EX_APPNAME != 'EX_SR' or EX_APPNAME is null)
group by class
;


/*******************************************************************************
*  Trying to validate resolution targets with calculations
*******************************************************************************/

SELECT INTERNALPRIORITY,
  SR.SITEID,
  ',=' || TICKETID,
  STATUS,
  TO_CHAR(SR.REPORTDATE, 'dd-MON-yy hh24:mi:ss') REPORTDATE,
--  TO_CHAR(SR.REPORTDATE, 'HH24') REPORTHOUR,
--  TO_CHAR(SR.REPORTDATE, 'DAY') REPORTDOW,
  TO_CHAR(SR.REPORTDATE + (80/9), 'dd-MON-yy hh24:mi:ss') CALCDTARGETFINISH,
  TO_CHAR(SR.REPORTDATE + (80/24), 'dd-MON-yy hh24:mi:ss') CALCDTARGETFINISH_24HR,
  TO_CHAR(TARGETFINISH, 'dd-MON-yy hh24:mi:ss') TARGETFINISH,
  TO_CHAR(ADJUSTEDTARGETRESOLUTIONTIME, 'dd-MON-yy hh24:mi:ss') ADJUSTEDTARGETRESOLUTIONTIME,
  SLARECORDS.SLANUM,
  TO_CHAR(SLARECORDS.RESOLUTIONDATE, 'dd-MON-yy hh24:mi:ss') RESOLUTIONDATE
FROM SR
LEFT JOIN SLARECORDS
ON SR.TICKETUID                     = SLARECORDS.OWNERID
WHERE ticketid = 'SR-31206'
order by ticketid;



select ',=' || TICKETID, TO_CHAR(REPORTDATE, 'hh24')
from sr
where INTERNALPRIORITY != 5
  and CREATIONDATE >= TO_DATE('01-JUL-15 00:00:00', 'dd-MON-yy hh24:mi:ss')
  and not exists (select 1 from SLARECORDS where ownerid = sr.ticketuid);


select TO_CHAR(REPORTDATE, 'hh24'), count(*)
from sr
where INTERNALPRIORITY != 5
  and CREATIONDATE >= TO_DATE('01-JUL-15 00:00:00', 'dd-MON-yy hh24:mi:ss')
  and not exists (select 1 from SLARECORDS where ownerid = sr.ticketuid)
group by TO_CHAR(REPORTDATE, 'hh24')
order by TO_CHAR(REPORTDATE, 'hh24') asc;

select ',=' || ticketid, ticketid, status, TO_CHAR(REPORTDATE, 'hh24'), ADJUSTEDTARGETRESOLUTIONTIME
from sr
where ASSETNUM is null 
  and CINUM is null
  and INTERNALPRIORITY != 5
  and CREATIONDATE >= TO_DATE('01-JUL-15 00:00:00', 'dd-MON-yy hh24:mi:ss');


/*******************************************************************************
*  Determine causes for lack of adjustedtargetresolutiontime/SLA application
*******************************************************************************/

select
  TICKETID,
  STATUS,
  CREATIONDATE,
  REPORTDATE,
  INTERNALPRIORITY,
  case when exists (select 1 from SLARECORDS where ownerid = sr.ticketuid) then 1 else null end HAS_SLA,
  case when ADJUSTEDTARGETRESOLUTIONTIME is not null then 1 else null end HAS_ATRT,
  TO_CHAR(REPORTDATE, 'hh24') REPORT_HOUR,
  TO_CHAR(SR.REPORTDATE, 'DAY') REPORTDOW,
  case when reportdate > TO_DATE('01-JUL-15 00:00:00', 'dd-MON-yy hh24:mi:ss') then 1 else null end REPORTED_RECENTLY
from sr
where SR.INTERNALPRIORITY != 5
  and SR.REPORTDATE is not null
order by SR.REPORTDATE desc;


/*******************************************************************************
*  Details of SRs
*******************************************************************************/

SELECT distinct TICKETID,
  ',=' || ticketid,
  TRUNC(CREATIONDATE, 'MON'),
  TO_CHAR(REPORTDATE, 'hh24'),
  INTERNALPRIORITY,
  WFTRANSACTION.PROCESSNAME,
  status,
  SLARECORDS.SLANUM,
  ADJUSTEDTARGETRESOLUTIONTIME
FROM ticket
LEFT JOIN SLARECORDS ON ticket.TICKETUID = SLARECORDS.OWNERID
LEFT JOIN WFTRANSACTION ON WFTRANSACTION.OWNERID = ticket.TICKETUID
WHERE (STATUS NOT       IN ('CLOSED','RESOLVED', 'CANCELED', 'DRAFT', 'REJECTED', 'INPRGINC'))
  and (WFTRANSACTION.PROCESSNAME is null
    or TICKET.ADJUSTEDTARGETRESOLUTIONTIME is null)
  and (ticket.INTERNALPRIORITY != '5' 
    or ticket.INTERNALPRIORITY is null)
ORDER BY TRUNC(CREATIONDATE, 'MON') DESC;