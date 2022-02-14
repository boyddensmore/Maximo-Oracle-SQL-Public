
/*******************************************************************************
* Cron Task Not Running
*  - When a Cron task fails, or is interrupted, sometimes the TASKSCHEDULER
*    entry is not updated correctly.  We need to find and delete these entries
*    so that Maximo can re-create them the next time the Cron runs.
*******************************************************************************/

select *
from taskscheduler
where taskname in (select crontaskname||'.'||instancename from CRONTASKINSTANCE where active=1)
    and lastrun is not null and lastrun > lastend
--    and lastrun >= sysdate - 5
;


delete
from taskscheduler
where taskname in (select crontaskname||'.'||instancename from CRONTASKINSTANCE where active=1)
    and lastrun is not null and lastrun > lastend
--    and lastrun >= sysdate - 5
;