/*******************************************************************************
*  SQL examples - Truncating dates
*******************************************************************************/

select 
  REPORTDATE, 
  trunc(REPORTDATE,'DD'), 
  trunc(REPORTDATE,'MON'), 
  trunc(REPORTDATE,'YYYY') 
from ticket;

select 
  TO_CHAR(REPORTDATE, 'dd-MON-yy hh24:mi:ss'), 
  TO_CHAR(REPORTDATE, 'DL') DATELONG, 
  TO_CHAR(REPORTDATE, 'DAY') DAYOFWEEK, 
  TO_CHAR(REPORTDATE, 'DS') DATESHORT, 
--  Trunc to minute
  TO_CHAR(trunc(REPORTDATE,'mi'), 'dd-MON-yy hh24:mi:ss') MINUTE, 
--  Trunc to hour
  TO_CHAR(trunc(REPORTDATE,'hh24'), 'dd-MON-yy hh24:mi:ss') HOUR, 
--  Trunc to day
  TO_CHAR(trunc(REPORTDATE,'DD'), 'dd-MON-yy hh24:mi:ss') DAY, 
--  Trunc to week
  TO_CHAR(trunc(REPORTDATE,'IW'), 'dd-MON-yy hh24:mi:ss') WEEK, 
--  Trunc to month
  TO_CHAR(trunc(REPORTDATE,'MON'), 'dd-MON-yy hh24:mi:ss') MONTH, 
-- Show quarter
  TO_CHAR(REPORTDATE, 'Q') QUARTER,
--  Trunc to year
  TO_CHAR(trunc(REPORTDATE,'YYYY'), 'dd-MON-yy hh24:mi:ss') YEAR
from ticket
order by REPORTDATE;


--  First day of a given month
select to_char(trunc(to_date('12','MM'),'MON'),'MM-DD') from dual;

-- First and last days of last month
select add_months(trunc(sysdate,'mm'),-1) FIRSTDAY, last_day(add_months(trunc(sysdate,'mm'),-1)) LASTDAY
--and creation_date between add_months(trunc(sysdate,'mm'),-1) and last_day(add_months(trunc(sysdate,'mm'),-1))
from dual;

-- Database information
select * from v$version;


/*******************************************************************************
*  Show all days in the past month.
*******************************************************************************/

define monthsago = -3;

select 
  -- For each row returned (see where clause), add the rownum (1, 2, 3, etc)
  -- to the first day of last month 
  -- (trunc(date, 'MON') returns the first second of the first day of the month of the date)
  -- There are some -1s and +2s below just to get the dates right.  Play with it.  :)
  rownum - 1 + trunc(add_months(sysdate, &monthsago), 'MON') DAY
from all_objects
-- Where rownum < number of days between the first day of the last month and the 
-- first day of this month.
where rownum <= (trunc(add_months(sysdate, &monthsago+1), 'MON')) -
               (trunc(add_months(sysdate, &monthsago), 'MON'));