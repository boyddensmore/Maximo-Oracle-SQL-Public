select 
  WFASSIGNMENT.WFASSIGNMENTID, 
  WOCHANGE.WONUM, 
  WOCHANGE.owner, 
  WOCHANGE.ownergroup,
  to_char(WOCHANGE.SCHEDSTART, 'dd-Mon-yy hh24:mi:ss') SCHEDSTART,
  WOCHANGE.SCHEDFINISH, 
  WOCHANGE.STATUS, WOCHANGE.DESCRIPTION CHANGE_DESC, 
  WOCHANGE.PMCHGTYPE, WOCHANGE.PMCHGCAT,
  WFASSIGNMENT.ASSIGNSTATUS, 
  WFASSIGNMENT.ORIGPERSON,
--  WFTRANSACTION.MEMO
  WFASSIGNMENT.ASSIGNCODE,
  case when (delegate is not null and sysdate >= DELEGATEFROMDATE and sysdate <= DELEGATETODATE) then 'YES' else 'NO' end ACTIVE_DELEGATE,
  WFASSIGNMENT.DESCRIPTION ASSGN_DESC,
  assignee.status assignee_status,
  assignee.DELEGATE,
  assignee.DELEGATEFROMDATE,
  assignee.DELEGATETODATE,
  CASE WHEN assigncode not in (select distinct respparty from persongroupteam) THEN 'NO' ELSE 'YES' END IN_PERSON_GROUP,
  CASE WHEN (assigncode not in (select userid from groupuser where groupname = 'CHGANL')) and assigncode not in ('[[USERNAME]]') THEN 'NO' ELSE 'YES' END IN_CHGANL
  WOCHANGE.SCHEDSTART, WOCHANGE.SCHEDFINISH
from WFASSIGNMENT
  join WOCHANGE on WFASSIGNMENT.OWNERID = WOCHANGE.WORKORDERID
  join person assignee on assignee.personid = WFASSIGNMENT.ASSIGNCODE
--  left join WFTRANSACTION on WFTRANSACTION.ASSIGNID = WFASSIGNMENT.ASSIGNID
where WFASSIGNMENT.APP = 'CHANGE'
  and WFASSIGNMENT.ASSIGNSTATUS not in ('COMPLETE', 'FORWARDED', 'INACTIVE')
  and WOCHANGE.STATUS not in ('COMP', 'REVIEW', 'IMPL', 'INPRG', 'CAN')
--  and WFASSIGNMENT.ASSIGNCODE in ('[[USERNAME]]')
--  and WFASSIGNMENT.DESCRIPTION = 'Approve or Reject Change CH-4965 (CAB)'
order by WOCHANGE.SCHEDSTART, WOCHANGE.WONUM, WOCHANGE.STATUS, WFASSIGNMENT.ASSIGNCODE;



/*******************************************************************************
*  Portlet
*******************************************************************************/

select wonum
from wochange CHG
where 
-- Below here is portlet portion.
exists
  (select 1
  from WFASSIGNMENT
    join WOCHANGE on WFASSIGNMENT.OWNERID = WOCHANGE.WORKORDERID
  where WFASSIGNMENT.APP = 'CHANGE'
    and WFASSIGNMENT.ASSIGNSTATUS not in ('COMPLETE', 'FORWARDED', 'INACTIVE')
    and WOCHANGE.STATUS not in ('COMP', 'REVIEW', 'IMPL', 'INPRG')
    and wochange.wonum = CHG.wonum)
;


