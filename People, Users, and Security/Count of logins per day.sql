
select attemptday, sum(logins) max_concurrent
from
    (SELECT
        to_char(trunc(attemptdate, 'HH'), 'yyyy-mm-dd hh24') || ':00' attemptday,
        case when servername in ('mif','rpt','ui','uic1', 'Shore_UI2', 'Shore_UI3') then 'SHORE' else servername end shore_vessel,
        max(currentcount) logins
    FROM
        maximo.logintracking
    WHERE
        attemptdate > SYSDATE - 60
--        and servername not in ('mif','rpt')
    group by trunc(attemptdate, 'HH'), case when servername in ('mif','rpt','ui','uic1', 'Shore_UI2', 'Shore_UI3') then 'SHORE' else servername end
    order by trunc(attemptdate, 'HH') desc, case when servername in ('mif','rpt','ui','uic1', 'Shore_UI2', 'Shore_UI3') then 'SHORE' else servername end)
group by attemptday
order by attemptday
;


select *
from
    (select attemptday, sum(logins) max_concurrent
    from
        (SELECT
            to_char(trunc(attemptdate, 'HH'), 'yyyy-mm-dd hh24') || ':00' attemptday,
            case when servername in ('mif','rpt','ui','uic1') then 'SHORE' else servername end shore_vessel,
            max(currentcount) logins
        FROM
            maximo.logintracking
        WHERE
            attemptdate > SYSDATE - 180
            and to_char(trunc(attemptdate, 'HH'), 'yyyy-mm-dd hh24') || ':00' = '2019-07-09 11:00'
            and servername not in ('mif','rpt')
        group by trunc(attemptdate, 'HH'), case when servername in ('mif','rpt','ui','uic1') then 'SHORE' else servername end
        order by trunc(attemptdate, 'HH'), case when servername in ('mif','rpt','ui','uic1') then 'SHORE' else servername end)
    group by attemptday
    order by attemptday asc)
;


SELECT
    to_char(attemptdate, 'yyyy-mm-dd hh24:mi:ss') attemptdayandhour, attemptresult, name, adminuserid, currentcount, clientaddr, servername,
    case when servername in ('mif','rpt','ui','uic1') then 'SHORE' else 'VESSEL-' || servername end shore_vessel
FROM
    maximo.logintracking
WHERE
    attemptdate > SYSDATE - 180
    and to_char(trunc(attemptdate, 'HH'), 'yyyy-mm-dd hh24') || ':00' = '2019-07-09 11:00'
--    and servername not in ('mif','rpt')
--group by trunc(attemptdate, 'HH'), case when servername in ('mif','rpt','ui','uic1') then 'SHORE' else servername end
order by attemptdate;




