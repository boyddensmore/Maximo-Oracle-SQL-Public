select 
--  WFASSIGNMENT.WFASSIGNMENTID, 
  WOCHANGE.WONUM, 
  WOCHANGE.owner, 
  WOCHANGE.ownergroup,
  case when (WOCHANGE.SCHEDSTART - sysdate) < 12  and WOCHANGE.SCHEDSTART > sysdate then 
    decode(trunc(WOCHANGE.SCHEDSTART, 'DD') - trunc(sysdate, 'DD'), 
      0, '       ---->', 
      1, '       ---->', 
      2, '       ---->', 
      3, '         -->', 
      4, '         -->', 
      5, '         -->', 
      ' ')
  else 
    case when (WOCHANGE.SCHEDSTART < sysdate and wochange.status not in ('SCHED_RETURNED', 'RESCHED') and WOCHANGE.EXAPPSTDCHG = 0) then '       >>>>-' else ' ' end
  end COMING_UP_1,
  to_char(WOCHANGE.SCHEDSTART, 'dd-Mon-yy hh24:mi:ss') SCHEDSTART,
  case when (WOCHANGE.SCHEDSTART - sysdate) < 2  and WOCHANGE.SCHEDSTART > sysdate then '<----' else 
    case when (WOCHANGE.SCHEDSTART < sysdate and wochange.status not in ('SCHED_RETURNED', 'RESCHED') and WOCHANGE.EXAPPSTDCHG = 0) then 
      decode(WOCHANGE.EXUNAUTHCHG, 0, '-<< Unauth?', 1, '-<< Unauth Confirmed')
    else 
      case when TO_CHAR(WOCHANGE.SCHEDSTART, 'D') in (7, 1, 2) then TO_CHAR(WOCHANGE.SCHEDSTART, 'Day') else ' ' end
    end
  end COMING_UP_2,
  WOCHANGE.SCHEDFINISH, 
  WOCHANGE.STATUS, WOCHANGE.DESCRIPTION CHANGE_DESC, 
  WOCHANGE.PMCHGTYPE, WOCHANGE.PMCHGCAT,
  WFASSIGNMENT.ASSIGNSTATUS, 
  WFASSIGNMENT.ORIGPERSON,
--  WFTRANSACTION.MEMO
  WFASSIGNMENT.ASSIGNCODE,
  case when (delegate is not null and sysdate >= DELEGATEFROMDATE and sysdate <= DELEGATETODATE) then 'YES' else 'NO' end ACTIVE_DELEGATE,
  case when (origperson != assigncode) then 'YES' else 'NO' end REASSIGNED,
  WFASSIGNMENT.DESCRIPTION ASSGN_DESC,
  assignee.status assignee_status,
  assignee.DELEGATE,
  assignee.DELEGATEFROMDATE,
  assignee.DELEGATETODATE,
  CASE WHEN assigncode not in (select distinct respparty from persongroupteam) THEN 'NO' ELSE 'YES' END IN_PERSON_GROUP,
  CASE WHEN (assigncode not in (select userid from groupuser where groupname = 'CHGANL')) and assigncode not in ('SSHANNON') THEN 'NO' ELSE 'YES' END IN_CHGANL
from WFASSIGNMENT
  join WOCHANGE on WFASSIGNMENT.OWNERID = WOCHANGE.WORKORDERID
  join person assignee on assignee.personid = WFASSIGNMENT.ASSIGNCODE
--  left join WFTRANSACTION on WFTRANSACTION.ASSIGNID = WFASSIGNMENT.ASSIGNID
where WFASSIGNMENT.APP = 'CHANGE'
  and WFASSIGNMENT.ASSIGNSTATUS not in ('COMPLETE', 'FORWARDED', 'INACTIVE')
--  and WFASSIGNMENT.ASSIGNCODE in ('[[USERNAME]]')
  and WOCHANGE.STATUS not in ('COMP', 'REVIEW', 'REVIEW_RETURNED', 'IMPL', 'INPRG', 'CAN')
--  and WOCHANGE.STATUS in ('REVIEW')
  -- Active Delegate
--  and (delegate is not null and sysdate >= DELEGATEFROMDATE and sysdate <= DELEGATETODATE)
--  and WFASSIGNMENT.DESCRIPTION = 'Configuration Manager to review CI details'
--  and WFASSIGNMENT.DESCRIPTION like '%(CAB)'
  -- Cases where a ticket was reassigned but the WF assignment wasn't
--  and wochange.owner != WFASSIGNMENT.ASSIGNCODE and wochange.status not in ('REVIEW', 'INPRG', 'AUTH', 'ASSESS', 'SCHED')
--and wonum = 'CH-6626'
order by WOCHANGE.SCHEDSTART, WOCHANGE.WONUM, WOCHANGE.STATUS, WFASSIGNMENT.ASSIGNCODE;
--order by WOCHANGE.SCHEDFINISH, WOCHANGE.WONUM, WOCHANGE.STATUS, WFASSIGNMENT.ASSIGNCODE;

/*******************************************************************************
*  Portlet
*******************************************************************************/


select wonum
from wochange CHG
where 
-- Below here is portlet portion.
exists
  (select wochange.wonum
  from WFASSIGNMENT
    join WOCHANGE on WFASSIGNMENT.OWNERID = WOCHANGE.WORKORDERID
  where WFASSIGNMENT.APP = 'CHANGE'
    and WFASSIGNMENT.ASSIGNSTATUS not in ('COMPLETE', 'FORWARDED', 'INACTIVE')
    and WFASSIGNMENT.DESCRIPTION = 'Configuration Manager to review CI details')
;

