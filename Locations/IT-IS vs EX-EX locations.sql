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
--  and location like 'SSC-1108%'
start with LOCHIERARCHY.LOCATION = 'ENMAX'
connect by nocycle prior LOCHIERARCHY.LOCATION = LOCHIERARCHY.PARENT
order by SYS_CONNECT_BY_PATH(LOCHIERARCHY.LOCATION, '\');


/*******************************************************************************
*  Count of locations by site
*******************************************************************************/
select siteid, count(*)
from locations
group by siteid;


/*******************************************************************************
*  Count of discrepancies
*******************************************************************************/

select
  (select count(*) from locations where SITEID = 'IT-IS' and location not in (select location from LOCATIONS where SITEID = 'EX-EX')) IT_AND_NOT_EX,
  (select count(*) from locations where SITEID = 'EX-EX' and location not in (select location from LOCATIONS where SITEID = 'IT-IS')) EX_AND_NOT_IT
from dual;


select location, DESCRIPTION from locations where SITEID = 'EX-EX' and location not in (select location from LOCATIONS where SITEID = 'IT-IS');

select
  round(((select count(*) from locations where siteid = 'IT-IS' and CLASSSTRUCTUREID is null) / (select count(*) from locations where siteid = 'IT-IS' and CLASSSTRUCTUREID is not null)) * 100, 1) || '% unclassified' unclassified_pct
from dual;