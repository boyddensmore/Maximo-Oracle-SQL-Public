/*******************************************************************************
*  Show all Migration Objects and Groups for an Object
*******************************************************************************/

select MAXINTOBJDETAIL.objectname "Object Name", MAXINTOBJECT.intobjectname "Object Structure", 
    DMCFGOBJECT.CFGOBJECT "Migration Object", 
    DMCFGGROUP.description, DMCFGGROUP.cfgobjgroup "Migration Group",
    MAXIFACEOUT.IFACENAME "Publish Channel",
    MAXEXTIFACEOUT.extsysname "PC External System",
    MAXIFACEIN.IFACENAME "Enterprise Service",
    MAXEXTIFACEIN.extsysname "ES External System"
from MAXINTOBJDETAIL
    left join MAXINTOBJECT on MAXINTOBJECT.intobjectname = MAXINTOBJDETAIL.intobjectname
    left join DMCFGOBJECT on DMCFGOBJECT.CFGOBJECT = MAXINTOBJECT.intobjectname
    left join DMCFGGROUP on DMCFGGROUP.cfgobjgroup = DMCFGOBJECT.cfgobjgroup
    left join MAXIFACEOUT on MAXIFACEOUT.intobjectname = MAXINTOBJECT.intobjectname
    left join MAXEXTIFACEOUT on MAXEXTIFACEOUT.IFACENAME = MAXIFACEOUT.IFACENAME
    left join MAXIFACEIN on MAXIFACEIN.intobjectname = MAXINTOBJECT.intobjectname
    left join MAXEXTIFACEIN on MAXEXTIFACEIN.IFACENAME = MAXIFACEIN.IFACENAME
where MAXINTOBJDETAIL.objectname = 'BILLTOSHIPTO'
;

/*******************************************************************************
*  Show all Objects contained within a Migration Package
*******************************************************************************/

select 
    DMPACKAGEDEF.PKGDEFNAME "Package Name",
    DMPACKAGEDEF.DESCRIPTION "Package Description",
    DMPKGCFGGRPDEF.CFGOBJGROUP "Migration Group",
    dmcfggroup.cfggrouporder "Migration Group Order",
    dmcfgobject.cfgobject "Migration Object",
    dmpkgcfgobjdef.whereclause "Migration Object Condition",
    maxintobjdetail.hierarchypath "Object Hierarchy",
    maxintobjdetail.objectorder "Object Level"
from DMPACKAGEDEF
    left join DMPKGCFGGRPDEF on DMPKGCFGGRPDEF.PKGDEFNAME = DMPACKAGEDEF.PKGDEFNAME
    left join DMCFGGROUP on dmcfggroup.cfgobjgroup = dmpkgcfggrpdef.cfgobjgroup
    left join DMCFGOBJECT on dmcfgobject.cfgobjgroup = dmcfggroup.cfgobjgroup
    left join DMPKGCFGOBJDEF on (dmpkgcfgobjdef.cfgobjgroup = DMCFGOBJECT.cfgobjgroup and dmpkgcfgobjdef.cfgobject = DMCFGOBJECT.cfgobject and dmpkgcfgobjdef.PKGDEFNAME = DMPACKAGEDEF.PKGDEFNAME)
    left join MAXINTOBJDETAIL on maxintobjdetail.intobjectname = dmcfgobject.cfgobject
where DMPACKAGEDEF.PKGDEFNAME = 'ReleaseID198'
order by DMPACKAGEDEF.PKGDEFNAME, dmcfggroup.cfggrouporder, dmcfgobject.cfgobject, maxintobjdetail.processorder, maxintobjdetail.objectorder
;

