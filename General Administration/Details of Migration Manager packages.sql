
/*******************************************************************************
*  Details of all objects included in a migration package
*******************************************************************************/

select distinct DMPACKAGE.source, DMPACKAGE.PKGDEFNAME, DMPKGCFGGRPDEF.CFGOBJGROUP, 
  DMCFGOBJECT.CFGOBJORDER, DMCFGOBJECT.CFGOBJECT, MAXINTOBJDETAIL.OBJECTNAME, 
  max(TO_DATE(substr(substr(DMPACKAGE.PACKAGE, length(DMPACKAGE.PACKAGE) - 13), 0, 8), 'yyyymmdd')) "DATE_UPDATED",
  to_char(max(DMPACKAGE.STATUSDATE), 'dd-MON-yy hh24:mi:ss') LASTRUN
from DMPKGCFGGRPDEF
  left join DMPACKAGE on DMPKGCFGGRPDEF.PKGDEFNAME = DMPACKAGE.PKGDEFNAME
  join DMPACKAGEDEF on DMPKGCFGGRPDEF.PKGDEFNAME = DMPACKAGEDEF.PKGDEFNAME
  join DMCFGOBJECT on DMPKGCFGGRPDEF.CFGOBJGROUP = DMCFGOBJECT.CFGOBJGROUP
  join MAXINTOBJECT on DMCFGOBJECT.CFGOBJECT = MAXINTOBJECT.INTOBJECTNAME
  join MAXINTOBJDETAIL on MAXINTOBJECT.INTOBJECTNAME = MAXINTOBJDETAIL.INTOBJECTNAME
where DMPACKAGE.STATUSDATE >= to_date('10-OCT-15 00:00:00', 'dd-MON-yy hh24:mi:ss')
--  and MAXINTOBJDETAIL.OBJECTNAME = 'TICKET'
  and DMPACKAGE.PKGDEFNAME in ('EX_SR-44790-2a', 'EX_SR-XXXXX')
group by DMPACKAGE.source, DMPACKAGE.PKGDEFNAME, DMPKGCFGGRPDEF.CFGOBJGROUP, 
  DMCFGOBJECT.CFGOBJORDER, DMCFGOBJECT.CFGOBJECT, MAXINTOBJDETAIL.OBJECTNAME
order by DMPACKAGE.PKGDEFNAME, DMPKGCFGGRPDEF.CFGOBJGROUP, DMCFGOBJECT.CFGOBJORDER, 
  DMCFGOBJECT.CFGOBJECT, MAXINTOBJDETAIL.OBJECTNAME;


select TO_DATE(substr(substr(DMPACKAGE.PACKAGE, length(DMPACKAGE.PACKAGE) - 13), 0, 8), 'yyyymmdd') "DATE_UPDATED", PACKAGE
from DMPACKAGE
order by TO_DATE(substr(substr(DMPACKAGE.PACKAGE, length(DMPACKAGE.PACKAGE) - 13), 0, 8), 'yyyymmdd') desc;

/*******************************************************************************
*  Packages by most recently deployed
*******************************************************************************/

select PKGDEFNAME, max(STATUSDATE) LATEST_MIGRATION
from DMPACKAGE
group by PKGDEFNAME
order by max(STATUSDATE) desc;


/*******************************************************************************
*  Count of deployments by migration package
*******************************************************************************/

select PKGDEFNAME, to_char(max(STATUSDATE), 'dd-MON-yy hh24:mi:ss') LATEST_MIGRATION, count(*)
from DMPACKAGE
group by PKGDEFNAME
order by count(*) desc;



/*******************************************************************************
*  Parsing 
*******************************************************************************/