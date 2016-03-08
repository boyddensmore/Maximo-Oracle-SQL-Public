-- Subquery showing members of TCS person groups
select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY'));

-- Show oldest login tracked in logintracking table
select to_char(min(attemptdate), 'mm-dd-yyyy hh:mi:ss') OLDEST_LOGIN
from logintracking;

-- Count of login attempts by TCS employees
select userid, count(logintrackingid)
from Logintracking
where userid in
  (select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
  or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY')))
  and Logintracking.Attemptresult = 'LOGIN'
group by userid
order by count(logintrackingid) asc;

-- TCS Employees who have not logged in in the past 30 days
select *
from Maxuser
where 
userid in
  -- TCS Users
  (select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
  or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY')))
and 
userid not in
  -- Users who have logged in
  (select distinct(userid)
  from Logintracking
  where 
  attemptresult = 'LOGIN' and 
  Logintracking.Attemptdate >= sysdate - 30);
  
  
-- Double check, show all logins
select *
from logintracking
where userid in ('RDAS', 'KDUTTA', 'RYADAV');
