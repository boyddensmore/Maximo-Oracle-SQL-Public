/********************************************************************************
*  New way, not fully tested
********************************************************************************/

select CLASSIFICATIONID, CLASSSTRUCTUREID, CONNECT_BY_ROOT CLASSSTRUCTUREID ROOT, PARENT, LEVEL, sys_connect_by_path(CLASSIFICATIONID, '\') HIERARCHYPATH
from CLASSSTRUCTURE
START WITH CLASSSTRUCTUREID = '1040'
connect by nocycle prior CLASSSTRUCTUREID = PARENT
order by sys_connect_by_path(CLASSIFICATIONID, '\');


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
