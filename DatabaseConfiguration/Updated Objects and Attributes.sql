/*******************************************************************************
* View changed objects and attributes
*******************************************************************************/

select MAXOBJECTCFG.objectname, MAXOBJECTCFG.changed,
    MAXATTRIBUTECFG.attributename, MAXATTRIBUTECFG.changed
from MAXOBJECTCFG
    left join MAXATTRIBUTECFG on (MAXATTRIBUTECFG.objectname = MAXOBJECTCFG.objectname and MAXATTRIBUTECFG.changed <> 'N')
where MAXOBJECTCFG.objectname = 'MAXUSER'
    or MAXOBJECTCFG.changed <> 'N';