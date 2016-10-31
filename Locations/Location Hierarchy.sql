/*******************************************************************************
*  Location hierarchy
*******************************************************************************/

select connect_by_root LOCATIONS.DESCRIPTION LOCATION_ROOT, level, lochierarchy.location, LOCATIONS.DESCRIPTION LOC_DESC, CLASSSTRUCTURE.DESCRIPTION LOC_CLASS, 
  SYS_CONNECT_BY_PATH(lochierarchy.location || ' (' || CLASSSTRUCTURE.DESCRIPTION || ')', ' >> ') PATH
from LOCHIERARCHY
  left join LOCATIONS on LOCHIERARCHY.location = LOCATIONS.location
  left join classstructure on LOCATIONS.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
start with lochierarchy.parent = 'ENMAX'
connect by prior lochierarchy.location = lochierarchy.parent
order by SYS_CONNECT_BY_PATH(lochierarchy.location || ' (' || CLASSSTRUCTURE.DESCRIPTION || ')', ' >> ')
;