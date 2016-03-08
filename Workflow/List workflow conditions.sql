
/*******************************************************************************
*  List all conditions on workflows to examine where clauses
*******************************************************************************/

select WFCONDITION.PROCESSNAME, WFCONDITION.NODEID, WFCONDITION.CONDITION, WFNODE.TITLE, WFNODE.NODETYPE, WFCONDITION.CONDITION
from WFCONDITION
  join wfnode on WFCONDITION.nodeid = WFNODE.NODEID
where WFCONDITION.PROCESSNAME in ('SRMAIN', 'INCMAIN')
  and WFNODE.PROCESSNAME = WFCONDITION.PROCESSNAME
  and upper(WFCONDITION.CONDITION) like '%STATUS%'
order by WFCONDITION.PROCESSNAME, WFCONDITION.NODEID;