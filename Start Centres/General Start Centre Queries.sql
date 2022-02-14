select kpimain.KPINAME, kpimain.Description, kpimain.owner, kpimain.reportnum, kpimain.lastupdated, kpimain.kpidate, kpimain.selectstmt, kpimain.clause
from kpimain;

select layout.portletid, layout.description
from layout;

select * from layout;

select *
from SCCONFIG;

/*******************************************************************************
*  List of KPIs in use on start centres for active people
*******************************************************************************/

--select *
select KPIGCONFIG.KPINAME, kpimain.DESCRIPTION, scconfig.DESCRIPTION START_CENTRE, kpimain.KPIDATE KPI_CREATED
--  , scconfig.USERID, scconfig.GROUPNAME
  , count(*) USER_COUNT
from KPIGCONFIG
  join layout on LAYOUT.LAYOUTID = KPIGCONFIG.LAYOUTID
  join scconfig on SCCONFIG.SCCONFIGID = LAYOUT.SCCONFIGID
  join kpimain on KPIMAIN.KPINAME = KPIGCONFIG.KPINAME
  join person on (person.personid = scconfig.USERID and person.status = 'ACTIVE')
group by KPIGCONFIG.KPINAME, kpimain.DESCRIPTION, scconfig.DESCRIPTION, kpimain.KPIDATE

--order by KPIGCONFIG.KPINAME, kpimain.DESCRIPTION, scconfig.DESCRIPTION, kpimain.KPIDATE
order by kpiname
;

select distinct portletid from layout;