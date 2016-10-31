/*******************************************************************************
*  New way, not fully tested
*******************************************************************************/

select CLASSSTRUCTURE.CLASSIFICATIONID, CLASSSTRUCTURE.CLASSSTRUCTUREID, CONNECT_BY_ROOT CLASSSTRUCTURE.CLASSSTRUCTUREID ROOT, 
  CLASSSTRUCTURE.PARENT, LEVEL, sys_connect_by_path(CLASSSTRUCTURE.CLASSIFICATIONID, '\') "HIERARCHYPATH"
from CLASSSTRUCTURE
where exists (select 1 from classusewith where classusewith.objectname = 'WOCHANGE' and CLASSUSEWITH.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID)
--START WITH CLASSSTRUCTUREID = '1040'
connect by nocycle prior CLASSSTRUCTURE.CLASSSTRUCTUREID = CLASSSTRUCTURE.PARENT
order by sys_connect_by_path(CLASSSTRUCTURE.CLASSIFICATIONID, '\');


/*******************************************************************************
*  New way (Locations), not fully tested
*******************************************************************************/

select LOCHIERARCHY.LOCATION, PARENT, level, SYS_CONNECT_BY_PATH(LOCHIERARCHY.LOCATION, '\') "LOCHIERARCHY", LOCATIONS.SITEID
from LOCHIERARCHY
  join LOCATIONS on LOCHIERARCHY.location = LOCATIONS.location
--start with LOCHIERARCHY.LOCATION = 'EP'
connect by nocycle prior LOCHIERARCHY.LOCATION = LOCHIERARCHY.PARENT
order by LOCATIONS.SITEID;


/*******************************************************************************
*  New way (People), not fully tested
*******************************************************************************/

select PERSONANCESTOR.PERSONID, PERSONANCESTOR.ANCESTOR, level, SYS_CONNECT_BY_PATH(PERSONANCESTOR.PERSONID, '\') "PERSONHIERARCHY"
--  , PERSONANCESTOR.HIERARCHYLEVELS
from PERSONANCESTOR
where HIERARCHYLEVELS not in (0)
--where level > 5
start with PERSONANCESTOR.PERSONID = 'GMANES'
connect by nocycle prior PERSONANCESTOR.PERSONID = PERSONANCESTOR.ANCESTOR
order by level;


/*******************************************************************************
*  Classstructure hierarchy using OOTB table
*******************************************************************************/

select ANCESTOR, ANCESTORCLASSID, CLASSIFICATIONID, CLASSSTRUCTUREID, HIERARCHYLEVELS
from CLASSANCESTOR
where ANCESTOR = '1245'
  or ANCESTOR in 
    (select CLASSSTRUCTUREID from CLASSANCESTOR where ANCESTOR = '1245')
order by ANCESTOR, HIERARCHYLEVELS, CLASSIFICATIONID;


/*******************************************************************************
*  Generate HIERARCHYPATH by concatenating up to 5 levels of classstructure
*  together
*******************************************************************************/

select Classstructure.Classstructureid,
  case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid HIERARCHYPATH
from Classstructure
  left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
  left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
  left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
  left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid;
--where Classstructure.Classstructureid in ('1107');




/*******************************************************************************
*  Example, showing all Location hierarchies
*******************************************************************************/

select Classstructure.Classstructureid,
  classstructure.classificationid,
  case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid HIERARCHYPATH,
  (select count(*) from locations where Locations.Classstructureid = Classstructure.Classstructureid) LOCATION_COUNT
from Classstructure
  left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
  left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
  left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
  left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid
  join classusewith on classstructure.classstructureid = classusewith.classstructureid
where classusewith.objectname = 'LOCATIONS';



/*******************************************************************************
*  Example, showing all SR hierarchies
*******************************************************************************/

select Classstructure.Classstructureid,
  classstructure.classificationid,
  case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid HIERARCHYPATH,
  (select count(*) from locations where Locations.Classstructureid = Classstructure.Classstructureid) LOCATION_COUNT
from Classstructure
  left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
  left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
  left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
  left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid
  join classusewith on classstructure.classstructureid = classusewith.classstructureid
where classusewith.objectname = 'SR'
order by case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid;