/*******************************************************************************
*  View hierarchy
*******************************************************************************/
-- Facilities

select siteid, LOCHIERARCHY.LOCATION, PARENT, level, CONNECT_BY_ROOT LOCHIERARCHY.LOCATION ROOT, SYS_CONNECT_BY_PATH(LOCHIERARCHY.LOCATION, '\') "LOCHIERARCHY"
from LOCHIERARCHY
where SITEID = 'EX-EX'
  and location like 'SSC%'
start with LOCHIERARCHY.LOCATION = 'EX-EX'
connect by nocycle prior LOCHIERARCHY.LOCATION = LOCHIERARCHY.PARENT
order by SYS_CONNECT_BY_PATH(LOCHIERARCHY.LOCATION, '\');

-- IT/IS
select siteid, LOCHIERARCHY.LOCATION, PARENT, level, CONNECT_BY_ROOT LOCHIERARCHY.LOCATION ROOT, SYS_CONNECT_BY_PATH(LOCHIERARCHY.LOCATION, '\') "LOCHIERARCHY"
from LOCHIERARCHY
where SITEID = 'IT-IS'
start with LOCHIERARCHY.LOCATION = '[[LOCATION]]'
connect by nocycle prior LOCHIERARCHY.LOCATION = LOCHIERARCHY.PARENT
order by SYS_CONNECT_BY_PATH(LOCHIERARCHY.LOCATION, '\');


/*******************************************************************************
*  Count of locations by site
*******************************************************************************/
select siteid, count(*)
from locations
group by siteid;

