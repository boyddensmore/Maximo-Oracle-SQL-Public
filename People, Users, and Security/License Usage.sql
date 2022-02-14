


/*******************************************************************************
* Basic user activity
*******************************************************************************/

--  Average logins per day over past 90 days
select ', =' || userid, round(count(*) , 0) logins
from logintracking
where attemptdate >= sysdate - 90
    and upper(servername) like '%UI%'
    and attemptresult = 'LOGIN'
    and exists (select 1 from maxuser where maxuser.userid = logintracking.userid and maxuser.status = 'ACTIVE')
    and not exists (select 1 from groupuser where groupuser.userid = logintracking.userid and groupuser.groupname = 'AUTHORIZED_NAMED_USER')
--    and exists (select 1 from groupuser where groupuser.userid = logintracking.userid and groupuser.groupname in ('MAXADMIN', 'CMMS_ADMIN'))
    and not exists (select 1 from MAXLICUSAGE where MAXLICUSAGE.userid = logintracking.userid and MAXLICUSAGE.licensenum = '1002' and MAXLICUSAGE.islatest = 1)
group by userid
order by count(*) desc
;



/*******************************************************************************
* Number of minutes sessions exist
*******************************************************************************/

select *
from
    (select
        to_date(:startdate, 'yyyy-mm-dd hh24') + ((rownum -1) / 24 / 6) periodstart,
        lead (to_date(:startdate, 'yyyy-mm-dd hh24') + ((rownum -1) / 24 / 6) - (1/24/60/60), 1) over (order by (to_date(:startdate, 'yyyy-mm-dd hh24') + ((rownum -1) / 24 / 6) - (1/24/60/60))) periodend
    from all_objects
    where rownum <= ((to_date(:enddate, 'yyyy-mm-dd hh24')-(1/24/6))-to_date(:startdate, 'yyyy-mm-dd hh24')+1) * 24 * 3.05) dateperiods
left join (select logintracking.maxsessionuid, logintracking.userid,
                login.logindate, logout.logoutdate,
                round((logout.logoutdate - login.logindate) * 24 * 60, 1) active_minutes
            from logintracking
                left join (select maxsessionuid, min(attemptdate) logindate from logintracking lt where attemptresult = 'LOGIN' group by maxsessionuid) login on login.maxsessionuid = logintracking.maxsessionuid
                left join (select maxsessionuid, max(attemptdate) logoutdate from logintracking lt where attemptresult in ('LOGOUT', 'TIMEOUT', 'RESTART') group by maxsessionuid) logout on logout.maxsessionuid = logintracking.maxsessionuid
            where upper(logintracking.servername) like '%UI%'
                and attemptresult = 'LOGIN') sessions on sessions.logindate <= dateperiods.periodend
                                                        and sessions.logoutdate >= dateperiods.periodstart
;


/**********************************************************************************************************
* Get active sessions during 1 minute sets between two dates and hours.  Updated to use new TYPE setup
***********************************************************************************************************/

select 
    periodstart,
    periodend,
    sum(PREMIUM_USER) PREMIUM_USER_sessions,
    sum(BASE_USER) BASE_USER_sessions,
    sum(LIMITED_USER) LIMITED_USER_sessions,
    sum(FREE_USER) FREE_USER_sessions,
    sum(PREMIUM_USER + BASE_USER + LIMITED_USER + FREE_USER) total_sessions
--    *
from
    (select
        to_date(:startdate, 'yyyy-mm-dd hh24') + ((rownum -1) / 24 / 60) periodstart,
        lead (to_date(:startdate, 'yyyy-mm-dd hh24') + ((rownum -1) / 24 / 60) - (1/24/60/60), 1) over (order by (to_date(:startdate, 'yyyy-mm-dd hh24') + ((rownum -1) / 24 / 60) - (1/24/60/60))) periodend
    from all_objects
    where rownum <= ((to_date(:enddate, 'yyyy-mm-dd hh24')-(1/24/60))-to_date(:startdate, 'yyyy-mm-dd hh24')+1) * 24 * 60) dateperiods
    left JOIN
        (select 
            login.logindate, logout.logoutdate,
            logintracking.maxsessionuid, logintracking.userid,
            case when TYPE = 'MASPREMIUM' then 1 else 0 end PREMIUM_USER,
            case when TYPE = 'MASBASE' then 1 else 0 end BASE_USER,
            case when TYPE = 'MASLIMITED' then 1 else 0 end LIMITED_USER,
            case when TYPE = 'MASFREE' then 1 else 0 end FREE_USER
        from maximo.logintracking
            LEFT JOIN maximo.MAXUSER ON LOGINTRACKING.USERID = MAXUSER.USERID
            left join (select maxsessionuid, min(attemptdate) logindate from maximo.logintracking lt where attemptresult = 'LOGIN' group by maxsessionuid) login on login.maxsessionuid = logintracking.maxsessionuid
            left join (select maxsessionuid, max(attemptdate) logoutdate from maximo.logintracking lt where attemptresult in ('LOGOUT', 'TIMEOUT', 'RESTART') group by maxsessionuid
                        union all 
                        select maxsessionuid, lastactivity logoutdate from maximo.maxsession
                        ) logout on logout.maxsessionuid = logintracking.maxsessionuid
        where upper(logintracking.servername) NOT IN ('MIF', 'RPT')
            and attemptresult = 'LOGIN'
            and attemptdate>= to_date(:startdate, 'yyyy-mm-dd hh24') - 10) sessions on sessions.logindate <= dateperiods.periodend
                                                    and sessions.logoutdate >= dateperiods.periodstart
group by periodstart, periodend
order by to_char(periodstart, 'yyyy-mm-dd'), periodstart, periodend
;


/*******************************************************************************
* For KPI, show only the last 10 minutes
*******************************************************************************/


select 
    periodstart,
    periodend,
    sum(PREMIUM_USER) PREMIUM_USER_sessions,
    sum(BASE_USER) BASE_USER_sessions,
    sum(LIMITED_USER) LIMITED_USER_sessions,
    sum(FREE_USER) FREE_USER_sessions,
    sum(PREMIUM_USER + BASE_USER + LIMITED_USER + FREE_USER) total_sessions
--    *
from
    (select
        to_date(:startdate, 'yyyy-mm-dd hh24') + ((rownum -1) / 24 / 60) periodstart,
        lead (to_date(:startdate, 'yyyy-mm-dd hh24') + ((rownum -1) / 24 / 60) - (1/24/60/60), 1) over (order by (to_date(:startdate, 'yyyy-mm-dd hh24') + ((rownum -1) / 24 / 60) - (1/24/60/60))) periodend
    from all_objects
    where rownum <= ((to_date(:enddate, 'yyyy-mm-dd hh24')-(1/24/60))-to_date(:startdate, 'yyyy-mm-dd hh24')+1) * 24 * 60) dateperiods
    left JOIN
        (select 
            login.logindate, logout.logoutdate,
            logintracking.maxsessionuid, logintracking.userid,
            case when TYPE = 'MASPREMIUM' then 1 else 0 end PREMIUM_USER,
            case when TYPE = 'MASBASE' then 1 else 0 end BASE_USER,
            case when TYPE = 'MASLIMITED' then 1 else 0 end LIMITED_USER,
            case when TYPE = 'MASFREE' then 1 else 0 end FREE_USER
        from maximo.logintracking
            LEFT JOIN maximo.MAXUSER ON LOGINTRACKING.USERID = MAXUSER.USERID
            left join (select maxsessionuid, min(attemptdate) logindate from maximo.logintracking lt where attemptresult = 'LOGIN' group by maxsessionuid) login on login.maxsessionuid = logintracking.maxsessionuid
            left join (select maxsessionuid, max(attemptdate) logoutdate from maximo.logintracking lt where attemptresult in ('LOGOUT', 'TIMEOUT', 'RESTART') group by maxsessionuid
                        union all 
                        select maxsessionuid, lastactivity logoutdate from maximo.maxsession
                        ) logout on logout.maxsessionuid = logintracking.maxsessionuid
        where upper(logintracking.servername) NOT IN ('MIF', 'RPT')
            and attemptresult = 'LOGIN'
            and attemptdate>= to_date(:startdate, 'yyyy-mm-dd hh24') - 10) sessions on sessions.logindate <= dateperiods.periodend
                                                    and sessions.logoutdate >= dateperiods.periodstart
group by periodstart, periodend
order by to_char(periodstart, 'yyyy-mm-dd'), periodstart, periodend
;





SELECT SUM(
case when TYPE = 'MASPREMIUM' then 15 else 0 end +
case when TYPE = 'MASBASE' then 10 else 0 end +
case when TYPE = 'MASLIMITED' then 5 else 0 END)


--    login.logindate, logout.logoutdate,
--    logintracking.maxsessionuid, logintracking.userid,
--    case when TYPE = 'MASPREMIUM' then 1 else 0 end PREMIUM_USER,
--    case when TYPE = 'MASBASE' then 1 else 0 end BASE_USER,
--    case when TYPE = 'MASLIMITED' then 1 else 0 end LIMITED_USER,
--    case when TYPE = 'MASFREE' then 1 else 0 end FREE_USER,
from maximo.logintracking
    LEFT JOIN maximo.MAXUSER ON LOGINTRACKING.USERID = MAXUSER.USERID
    left join (select maxsessionuid, min(attemptdate) logindate from maximo.logintracking lt where attemptresult = 'LOGIN' group by maxsessionuid) login on login.maxsessionuid = logintracking.maxsessionuid
    left join (select maxsessionuid, max(attemptdate) logoutdate from maximo.logintracking lt where attemptresult in ('LOGOUT', 'TIMEOUT', 'RESTART') group by maxsessionuid
                union all 
                select maxsessionuid, lastactivity logoutdate from maximo.maxsession
                ) logout on logout.maxsessionuid = logintracking.maxsessionuid
where upper(logintracking.servername) NOT IN ('MIF', 'RPT')
    and attemptresult = 'LOGIN'
    and attemptdate>= (SYSDATE - (1/24/6))

SELECT SUM( 
case when TYPE = 'MASPREMIUM' then 15 else 0 end +
case when TYPE = 'MASBASE' then 10 else 0 end +
case when TYPE = 'MASLIMITED' then 5 else 0 END) POINTS
from
(SELECT DISTINCT maxsession.userid
FROM maximo.maxsession) sessions
LEFT JOIN maximo.maxuser ON sessions.userid = maxuser.userid
;

SELECT RECORDEDON, KPIVALUE
FROM maximo.KPIHISTORY
WHERE KPIMAINID = (SELECT kpimainid FROM maximo.kpimain WHERE KPINAME = 'LICMGMT-CONCURRENTPOINTS')
ORDER BY RECORDEDON DESC
;








