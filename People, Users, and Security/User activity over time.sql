
/*******************************************************************************
* Compare number of completed WO, May to August, 2018 vs 2019
*******************************************************************************/

select monthlystats.vesstermid,
    'WO' rectype,
    to_char(monthlystats.changemonth, 'yyyy') changeyear,
    monthlystats.changemonth,
    monthlystats.time_range,
    monthlystats.changes,
    (case when trunc(sysdate, 'mm') = trunc(monthlystats.changemonth,'mm') then trunc(sysdate, 'dd') else last_day(trunc(monthlystats.changemonth,'mm')) end - trunc(monthlystats.changemonth,'mm') + 1) days_in_month,
    round(monthlystats.changes / (last_day(trunc(monthlystats.changemonth,'mm')) - trunc(monthlystats.changemonth,'mm') + 1), 1) changes_per_day_in_month,
    totalstats.avg_daily_changes average_daily_during_year
from
    (select workorder.vesstermid,
        trunc(wostatus.changedate, 'MM') changemonth,
        case
            when to_number(to_char(wostatus.changedate, 'hh24')) between 7 and 14 then '07:00 - 14:59'
            when to_number(to_char(wostatus.changedate, 'hh24')) between 15 and 22 then '15:00 - 23:59'
            when to_number(to_char(wostatus.changedate, 'hh24')) between 0 and 7 then '00:00 to 07:59'
        end as time_range,
        count(*) changes
    from wostatus
        left join workorder on workorder.wonum = wostatus.wonum
    where woclass = 'WORKORDER'
        and exists (select 1 from alndomain where domainid = 'BCFWOGENVESSTERMID' and value = workorder.vesstermid)
        and (not exists (select 1 from groupuser where groupname in ('CMMS_ADMIN', 'MAXADMIN') and groupuser.userid = wostatus.changeby)
            or wostatus.changeby in ('MAXADMIN', 'MXINTADM'))
        and to_char(wostatus.changedate, 'yyyy') in ('2018', '2019')
        and to_char(wostatus.changedate, 'mm') in ('05', '06', '07', '08')
    group by rollup(workorder.vesstermid, trunc(wostatus.changedate, 'MM'), 
        case
            when to_number(to_char(wostatus.changedate, 'hh24')) between 7 and 14 then '07:00 - 14:59'
            when to_number(to_char(wostatus.changedate, 'hh24')) between 15 and 22 then '15:00 - 23:59'
            when to_number(to_char(wostatus.changedate, 'hh24')) between 0 and 7 then '00:00 to 07:59'
        end)) monthlystats
    
    join (select workorder.vesstermid,
        to_char(wostatus.changedate, 'yyyy') changeyear,
        round(count(*) / (max(wostatus.changedate) - min(wostatus.changedate) + .000000001), 1) avg_daily_changes
    from wostatus
        left join workorder on workorder.wonum = wostatus.wonum
    where woclass = 'WORKORDER'
        and exists (select 1 from alndomain where domainid = 'BCFWOGENVESSTERMID' and value = workorder.vesstermid)
        and (not exists (select 1 from groupuser where groupname in ('CMMS_ADMIN', 'MAXADMIN') and groupuser.userid = wostatus.changeby)
            or wostatus.changeby in ('MAXADMIN', 'MXINTADM'))
        and to_char(wostatus.changedate, 'yyyy') in ('2018', '2019')
        and to_char(wostatus.changedate, 'mm') in ('05', '06', '07', '08')
    group by workorder.vesstermid, to_char(wostatus.changedate, 'yyyy')) totalstats on (totalstats.vesstermid = monthlystats.vesstermid and totalstats.changeyear = to_char(monthlystats.changemonth, 'yyyy'))

union

/*******************************************************************************
* Compare number of completed SR, May to August, 2018 vs 2019
*******************************************************************************/

select monthlystats.vesstermid,
    'SR' rectype,
    to_char(monthlystats.changemonth, 'yyyy') changeyear,
    monthlystats.changemonth,
    monthlystats.time_range,
    monthlystats.changes,
    (case when trunc(sysdate, 'mm') = trunc(monthlystats.changemonth,'mm') then trunc(sysdate, 'dd') else last_day(trunc(monthlystats.changemonth,'mm')) end - trunc(monthlystats.changemonth,'mm') + 1) days_in_month,
    round(monthlystats.changes / (last_day(trunc(monthlystats.changemonth,'mm')) - trunc(monthlystats.changemonth,'mm') + 1), 1) changes_per_day_in_month,
    totalstats.avg_daily_changes average_daily_during_year
from
    (select locations.vesstermid,
        trunc(tkstatus.changedate, 'MM') changemonth,
        case
            when to_number(to_char(tkstatus.changedate, 'hh24')) between 7 and 14 then '07:00 - 14:59'
            when to_number(to_char(tkstatus.changedate, 'hh24')) between 15 and 22 then '15:00 - 23:59'
            when to_number(to_char(tkstatus.changedate, 'hh24')) between 0 and 7 then '00:00 to 07:59'
        end as time_range,
        count(*) changes
    from tkstatus
        left join sr on sr.ticketid = tkstatus.ticketid
        left join locations on locations.location = sr.location
    where exists (select 1 from alndomain where domainid = 'BCFWOGENVESSTERMID' and value = locations.vesstermid)
        and (not exists (select 1 from groupuser where groupname in ('CMMS_ADMIN', 'MAXADMIN') and groupuser.userid = tkstatus.changeby)
            or tkstatus.changeby in ('MAXADMIN', 'MXINTADM'))
        and to_char(tkstatus.changedate, 'yyyy') in ('2018', '2019')
        and to_char(tkstatus.changedate, 'mm') in ('05', '06', '07', '08')
    group by rollup(locations.vesstermid, trunc(tkstatus.changedate, 'MM'),
        case
            when to_number(to_char(tkstatus.changedate, 'hh24')) between 7 and 14 then '07:00 - 14:59'
            when to_number(to_char(tkstatus.changedate, 'hh24')) between 15 and 22 then '15:00 - 23:59'
            when to_number(to_char(tkstatus.changedate, 'hh24')) between 0 and 7 then '00:00 to 07:59'
        end)) monthlystats
    
    join (select locations.vesstermid,
        to_char(tkstatus.changedate, 'yyyy') changeyear,
        round(count(*) / (max(tkstatus.changedate) - min(tkstatus.changedate) + .000000001), 1) avg_daily_changes
    from tkstatus
        left join sr on sr.ticketid = tkstatus.ticketid
        left join locations on locations.location = sr.location
    where exists (select 1 from alndomain where domainid = 'BCFWOGENVESSTERMID' and value = locations.vesstermid)
        and (not exists (select 1 from groupuser where groupname in ('CMMS_ADMIN', 'MAXADMIN') and groupuser.userid = tkstatus.changeby)
            or tkstatus.changeby in ('MAXADMIN', 'MXINTADM'))
        and to_char(tkstatus.changedate, 'yyyy') in ('2018', '2019')
        and to_char(tkstatus.changedate, 'mm') in ('05', '06', '07', '08')
    group by locations.vesstermid, to_char(tkstatus.changedate, 'yyyy')) totalstats on (totalstats.vesstermid = monthlystats.vesstermid and totalstats.changeyear = to_char(monthlystats.changemonth, 'yyyy'))

union

/*******************************************************************************
* Compare number of completed MR, May to August, 2018 vs 2019
*******************************************************************************/

select monthlystats.vesstermid,
    'MR' rectype,
    to_char(monthlystats.changemonth, 'yyyy') changeyear,
    monthlystats.changemonth,
    monthlystats.time_range,
    monthlystats.changes,
    (case when trunc(sysdate, 'mm') = trunc(monthlystats.changemonth,'mm') then trunc(sysdate, 'dd') else last_day(trunc(monthlystats.changemonth,'mm')) end - trunc(monthlystats.changemonth,'mm') + 1) days_in_month,
    round(monthlystats.changes / (last_day(trunc(monthlystats.changemonth,'mm')) - trunc(monthlystats.changemonth,'mm') + 1), 1) changes_per_day_in_month,
    totalstats.avg_daily_changes average_daily_during_year
from
    (select locations.vesstermid,
        trunc(mrstatus.changedate, 'MM') changemonth,
        case
            when to_number(to_char(mrstatus.changedate, 'hh24')) between 7 and 14 then '07:00 - 14:59'
            when to_number(to_char(mrstatus.changedate, 'hh24')) between 15 and 22 then '15:00 - 23:59'
            when to_number(to_char(mrstatus.changedate, 'hh24')) between 0 and 7 then '00:00 to 07:59'
        end as time_range,
        count(*) changes
    from mrstatus
        left join mr on mr.mrnum = mrstatus.mrnum
        left join locations on locations.location = mr.location
    where exists (select 1 from alndomain where domainid = 'BCFWOGENVESSTERMID' and value = locations.vesstermid)
        and (not exists (select 1 from groupuser where groupname in ('CMMS_ADMIN', 'MAXADMIN') and groupuser.userid = mrstatus.changeby)
            or mrstatus.changeby in ('MAXADMIN', 'MXINTADM'))
        and to_char(mrstatus.changedate, 'yyyy') in ('2018', '2019')
        and to_char(mrstatus.changedate, 'mm') in ('05', '06', '07', '08')
    group by rollup(locations.vesstermid, trunc(mrstatus.changedate, 'MM'),
        case
            when to_number(to_char(mrstatus.changedate, 'hh24')) between 7 and 14 then '07:00 - 14:59'
            when to_number(to_char(mrstatus.changedate, 'hh24')) between 15 and 22 then '15:00 - 23:59'
            when to_number(to_char(mrstatus.changedate, 'hh24')) between 0 and 7 then '00:00 to 07:59'
        end)) monthlystats
    
    join (select locations.vesstermid,
        to_char(mrstatus.changedate, 'yyyy') changeyear,
        round(count(*) / (max(mrstatus.changedate) - min(mrstatus.changedate) + .000000001), 1) avg_daily_changes
    from mrstatus
        left join mr on mr.mrnum = mrstatus.mrnum
        left join locations on locations.location = mr.location
    where exists (select 1 from alndomain where domainid = 'BCFWOGENVESSTERMID' and value = locations.vesstermid)
        and (not exists (select 1 from groupuser where groupname in ('CMMS_ADMIN', 'MAXADMIN') and groupuser.userid = mrstatus.changeby)
            or mrstatus.changeby in ('MAXADMIN', 'MXINTADM'))
        and to_char(mrstatus.changedate, 'yyyy') in ('2018', '2019')
        and to_char(mrstatus.changedate, 'mm') in ('05', '06', '07', '08')
    group by locations.vesstermid, to_char(mrstatus.changedate, 'yyyy')) totalstats on (totalstats.vesstermid = monthlystats.vesstermid and totalstats.changeyear = to_char(monthlystats.changemonth, 'yyyy'))
order by vesstermid, rectype, changemonth, time_range desc
;

/*******************************************************************************
* Login / Logout / Timeout over last 90 days with servername
*******************************************************************************/
select  
        to_char(login.attemptdate, 'YYYY') as login_year,
        to_char(trunc(login.attemptdate, 'MM'), 'yyyy-mm-dd') as login_month,
        CASE
          WHEN logout.attemptresult is not null
            THEN logout.attemptresult
          WHEN timeout.attemptresult is not null
            THEN timeout.attemptresult
        END as END_SESSION,
        count(*) count,
        round(avg(
            CASE
              WHEN logout.attemptdate is not null
                THEN Round((logout.attemptdate - login.attemptdate)*24*60, 2)
              WHEN timeout.attemptdate is not null
                THEN Round(((timeout.attemptdate - login.attemptdate)*24*60) - 60, 2)
            END), 2) as sessiontime_in_minutes
from logintracking login
    left join logintracking logout 
      ON login.maxsessionuid = logout.MAXSESSIONUID 
        AND logout.attemptresult = 'LOGOUT' 
        AND logout.MAXSESSIONUID != 0 
        AND login.servername = logout.servername
    left join logintracking timeout 
      ON login.maxsessionuid = timeout.maxsessionuid 
        AND timeout.attemptresult = 'TIMEOUT' 
        AND timeout.maxsessionuid != 0 
        AND login.servername = timeout.servername
where login.attemptresult = 'LOGIN'
    AND login.attemptdate > to_date('2019-01-01', 'yyyy-mm-dd')
    and exists (select 1 from maxuser where sysuser = 0 and maxuser.userid = login.userid)
    and (logout.attemptresult is not null or timeout.attemptresult is not null)
    AND ((EXISTS (SELECT 1 FROM dual where sys_context('USERENV','DB_NAME') = 'CENTMP76') 
          AND login.servername IN ('ui', 'uic1', 'Shore_UI3', 'Shore_UI2'))
      OR (EXISTS (SELECT 1 FROM dual where sys_context('USERENV','DB_NAME') = 'SHIPMX76') 
          AND login.servername NOT IN ('mif', 'ui', 'rpt', 'uic1', 'Shore_UI3', 'Shore_UI2')))

AND NOT EXISTS (select 1 from maxsession where maxsession.userid = login.userid and maxsession.maxsessionuid = login.maxsessionuid)
and not (CASE 
          WHEN logout.attemptdate is not null
            THEN Round((logout.attemptdate - login.attemptdate)*24*60, 2)
          WHEN timeout.attemptdate is not null
            THEN Round((timeout.attemptdate - login.attemptdate)*24*60, 2)
        END > 1000
        and CASE
          WHEN logout.attemptdate is not null
            THEN to_char(logout.attemptdate, 'yy-mm-dd hh24:mi:ss')
          WHEN timeout.attemptdate is not null
            THEN to_char(timeout.attemptdate, 'yy-mm-dd hh24:mi:ss')
        END = '19-05-30 22:09:01')
group by to_char(login.attemptdate, 'YYYY'),
        trunc(login.attemptdate, 'MM'),
        CASE
          WHEN logout.attemptresult is not null
            THEN logout.attemptresult
          WHEN timeout.attemptresult is not null
            THEN timeout.attemptresult
        END
order by to_char(login.attemptdate, 'YYYY'),
        trunc(login.attemptdate, 'MM'),
        CASE
          WHEN logout.attemptresult is not null
            THEN logout.attemptresult
          WHEN timeout.attemptresult is not null
            THEN timeout.attemptresult
        END
;
