-- Working hrs, 08:00 - 17:00 (9 hours per workday)
-- 80 hours (SLA) == 8.88888 9 hr work days

/*******************************************************************************
*  Show details of calculated values - for validation
*  WIP!!  Just included holidays to play
*  More accurate examples can be found in Calculating SLA Meets folder
*******************************************************************************/

SELECT ticketid,
  TO_CHAR(REPORTDATE, 'dd-MON-yy hh24:mi') REPORTDATE,
  TO_CHAR(REPORTDATE + (80 /9), 'dd-MON-yy hh24:mi') REPORTDATE_PLUS_9_days,
  (SELECT COUNT(*)
     FROM DUAL
     WHERE TO_CHAR(REPORTDATE + LEVEL - 1, 'DY') IN ('SAT', 'SUN')
     CONNECT BY LEVEL <= REPORTDATE - REPORTDATE + 1 + (80 /9)
  ) as WeekendDay_Count,
  SR.EX_SUPPORTCALENDAR,
  (SELECT COUNT(*)
     FROM DUAL
     WHERE to_char(REPORTDATE + LEVEL - 1, 'dd-Mon-yy') IN 
        ('11-Nov-14','25-Dec-14','26-Dec-14','16-Feb-15','03-Apr-15',
         '06-Apr-15','18-May-15','07-Sep-15','25-Dec-15','26-Dec-15',
         '27-Dec-15','30-Dec-15','31-Dec-15','01-Jan-15','01-Jul-15',
         '03-Aug-15','12-Oct-15','11-Nov-15','24-Dec-15','28-Dec-15',
         '29-Dec-15')
     CONNECT BY LEVEL <= REPORTDATE - REPORTDATE + 1 + (80 /9)
  ) as Holiday_Count,
  TO_CHAR(REPORTDATE + (80 /9) +
    (SELECT COUNT(*)
       FROM DUAL
       WHERE TO_CHAR(REPORTDATE + LEVEL - 1, 'DY') IN ('SAT', 'SUN')
       CONNECT BY LEVEL <= REPORTDATE - REPORTDATE + 1 + (80 /9)
    ), 'dd-MON-yy hh24:mi') ADJUSTED_DATE,
    SR.ADJUSTEDTARGETRESOLUTIONTIME
FROM SR
where SR.EX_SUPPORTCALENDAR in (null, 'BRONZE')
  and SR.ADJUSTEDTARGETRESOLUTIONTIME is not null;

-- Maximo holidays
select WORKDATE, trunc(WORKDATE, 'DD') from WORKPERIOD where SHIFTNUM = 'HOLIDAY';

select EX_SUPPORTCALENDAR, count(*)
from sr
group by EX_SUPPORTCALENDAR
order by EX_SUPPORTCALENDAR;

/*******************************************************************************
*  Update ticket resolution targets - BRONZE only
*******************************************************************************/

update SR
set ADJUSTEDTARGETRESOLUTIONTIME = 
  REPORTDATE + (80 /9) +
    (SELECT COUNT(*)
       FROM DUAL
       WHERE TO_CHAR(REPORTDATE + LEVEL - 1, 'DY') IN ('SAT', 'SUN')
       CONNECT BY LEVEL <= REPORTDATE - REPORTDATE + 1 + (80/9)
    )
where 
  ADJUSTEDTARGETRESOLUTIONTIME is null
  and EX_SUPPORTCALENDAR = 'BRONZE'
  and ticketid in ('SR-10001', 'SR-10002', 'SR-10006', 'SR-10008', 'SR-10009');


/*******************************************************************************
*  Calculate how many business hours/days it took to respond to tickets.
*******************************************************************************/

select class, EX_SUPPORTCALENDAR, INTERNALPRIORITY, TO_CHAR(REPORTDATE, 'dd-MON-yy hh24:mi:ss') REPORTDATE, TO_CHAR(ACTUALSTART, 'dd-MON-yy hh24:mi:ss') ACTUALSTART,
  round(ACTUALSTART - REPORTDATE, 8) CALDAYS,
  (SELECT COUNT(*)
   FROM DUAL
   WHERE TO_CHAR(REPORTDATE + LEVEL - 1, 'DY') IN ('SAT', 'SUN')
   CONNECT BY LEVEL <= ACTUALSTART - REPORTDATE
    ) WEEKEND_DAYS,
  (SELECT COUNT(*)
     FROM DUAL
     WHERE to_char(REPORTDATE + LEVEL - 1, 'dd-Mon-yy') IN 
        ('11-Nov-14','25-Dec-14','26-Dec-14','16-Feb-15','03-Apr-15',
         '06-Apr-15','18-May-15','07-Sep-15','25-Dec-15','26-Dec-15',
         '27-Dec-15','30-Dec-15','31-Dec-15','01-Jan-15','01-Jul-15',
         '03-Aug-15','12-Oct-15','11-Nov-15','24-Dec-15','28-Dec-15',
         '29-Dec-15')
     CONNECT BY LEVEL <= ACTUALSTART - REPORTDATE
  ) as HOLIDAYS,
  round(ACTUALSTART - REPORTDATE
        - (SELECT COUNT(*)
           FROM DUAL
           WHERE TO_CHAR(REPORTDATE + LEVEL - 1, 'DY') IN ('SAT', 'SUN')
           CONNECT BY LEVEL <= ACTUALSTART - REPORTDATE
            )
        - (SELECT COUNT(*)
           FROM DUAL
           WHERE to_char(REPORTDATE + LEVEL - 1, 'dd-Mon-yy') IN 
              ('11-Nov-14','25-Dec-14','26-Dec-14','16-Feb-15','03-Apr-15',
               '06-Apr-15','18-May-15','07-Sep-15','25-Dec-15','26-Dec-15',
               '27-Dec-15','30-Dec-15','31-Dec-15','01-Jan-15','01-Jul-15',
               '03-Aug-15','12-Oct-15','11-Nov-15','24-Dec-15','28-Dec-15',
               '29-Dec-15')
           CONNECT BY LEVEL <= ACTUALSTART - REPORTDATE
          )
  , 8) ADJUSTEDDAYS,
  round((ACTUALSTART - REPORTDATE
        - (SELECT COUNT(*)
           FROM DUAL
           WHERE TO_CHAR(REPORTDATE + LEVEL - 1, 'DY') IN ('SAT', 'SUN')
           CONNECT BY LEVEL <= ACTUALSTART - REPORTDATE
            )
        - (SELECT COUNT(*)
           FROM DUAL
           WHERE to_char(REPORTDATE + LEVEL - 1, 'dd-Mon-yy') IN 
              ('11-Nov-14','25-Dec-14','26-Dec-14','16-Feb-15','03-Apr-15',
               '06-Apr-15','18-May-15','07-Sep-15','25-Dec-15','26-Dec-15',
               '27-Dec-15','30-Dec-15','31-Dec-15','01-Jan-15','01-Jul-15',
               '03-Aug-15','12-Oct-15','11-Nov-15','24-Dec-15','28-Dec-15',
               '29-Dec-15')
           CONNECT BY LEVEL <= ACTUALSTART - REPORTDATE
          )
  ) * 24, 8) ADJUSTEDHOURS
from ticket
where ACTUALSTART is not null
  and to_char(REPORTDATE, 'DY') not IN ('SAT', 'SUN')
  and to_char(REPORTDATE, 'dd-Mon-yy') NOT IN 
        ('11-Nov-14','25-Dec-14','26-Dec-14','16-Feb-15','03-Apr-15',
         '06-Apr-15','18-May-15','07-Sep-15','25-Dec-15','26-Dec-15',
         '27-Dec-15','30-Dec-15','31-Dec-15','01-Jan-15','01-Jul-15',
         '03-Aug-15','12-Oct-15','11-Nov-15','24-Dec-15','28-Dec-15',
         '29-Dec-15');