
/*******************************************************************************
*  List all conditions on active workflows to examine where clauses
*******************************************************************************/

select WFCONDITION.PROCESSNAME, WFCONDITION.NODEID, WFCONDITION.PROCESSREV, WFCONDITION.CONDITION, WFNODE.TITLE, WFNODE.NODETYPE, WFCONDITION.CONDITION
from WFCONDITION
  join wfprocess on (WFPROCESS.PROCESSNAME = WFCONDITION.PROCESSNAME and WFPROCESS.ACTIVE = '1')
  join wfnode on (WFCONDITION.nodeid = WFNODE.NODEID and WFCONDITION.PROCESSREV = WFNODE.PROCESSREV and WFCONDITION.PROCESSNAME = WFNODE.PROCESSNAME and wfnode.processrev = wfprocess.processrev)
where WFCONDITION.PROCESSNAME in ('SRMAIN', 'INCMAIN', 'EX_CHG')
--  and upper(WFCONDITION.CONDITION) like '%STATUS%'
order by WFCONDITION.PROCESSNAME, WFCONDITION.NODEID;
