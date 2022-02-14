/*******************************************************************************
* Rank users by server login count, return top 5 records
*******************************************************************************/

select *
from
    (select serverhost, 
        userid, 
        count(*) USER_LOGINS,
        RANK() OVER (PARTITION BY serverhost
        ORDER BY count(*) DESC) USERSVRRANK
    from (select count(*) count from logintracking
            where attemptdate >= to_date('2018-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss') 
                and attemptresult = 'LOGIN'
                and userid not in ('[[USERIDS]]')
            group by serverhost) TOTAL_LOGINS
        join logintracking on 1=1
    where attemptdate >= to_date('2018-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss') 
        and attemptresult = 'LOGIN'
        and userid not in ('[[USERIDS]]')
    group by serverhost, userid
    order by count(*) desc) DATA
where USERSVRRANK <= 5
;