/*******************************************************************************
*  Show all changes running a workflow which isn't the most recent revision
*******************************************************************************/

select 
  ', =' || wochange.wonum, wochange.wonum, WOCHANGE.STATUS, WFINSTANCE.PROCESSNAME, WFINSTANCE.PROCESSREV
--  count(*)
from wochange
  join WFINSTANCE on (WFINSTANCE.OWNERID = WOCHANGE.WORKORDERID and WFINSTANCE.OWNERTABLE = 'WOCHANGE' and WFINSTANCE.ACTIVE = '1')
--where wochange.wonum = 'CH-5665'
where 1=1
  and processrev != (select max(processrev) from wfinstance where WFINSTANCE.processname = 'EX_CHG' and active = 1)
--  and wonum in ('CH-6221')
--  and status in ('REVIEW')
order by processrev, status
;

/*******************************************************************************
*  Config review stats
*******************************************************************************/

select 
--  *
  case when
    grouping(
      case when ((wochange.ownergroup like 'LVS-%') or (wochange.ownergroup = 'VEN-INFRASTRUCTURE-PRJ')) then 'LVS' else 
      case when (wochange.ownergroup like 'TCS-%') then 'TCS' else 'ENMAX' end
    end) = 1 then 'MONTH' else 'COMPANY' end GROUP_LEVEL,
  
  to_char(trunc(transdate, 'MON'), 'Mon yyyy') MONTH,
  case when ((wochange.ownergroup like 'LVS-%') or (wochange.ownergroup = 'VEN-INFRASTRUCTURE-PRJ')) then 'LVS' else 
    case when (wochange.ownergroup like 'TCS-%') then 'TCS' else 'ENMAX' end
  end COMPANY,
  
  count(*) TOTAL,
  sum(case when WFTRANSACTION.transtype = 'ACCEPT' then 1 else null end) ACCEPTED,
  sum(case when WFTRANSACTION.transtype = 'REJECT' then 1 else null end) REJECTED,
  round((sum(case when WFTRANSACTION.transtype = 'ACCEPT' then 1 else null end) / count(*)) * 100, 2) ACCEPTED_PERCENT,
  round((sum(case when WFTRANSACTION.transtype = 'REJECT' then 1 else null end) / count(*)) * 100, 2) REJECTED_PERCENT
from WFTRANSACTION
  join wochange on ownerid = workorderid
where 1=1
--  and personid = 'BDENSMOR'
  and WFTRANSACTION.processname = 'EX_CHG'
  and WFTRANSACTION.transtype in ('ACCEPT', 'REJECT')
  and nodeid in (select nodeid from wfnode where wfnode.processname = WFTRANSACTION.processname and wfnode.title = 'REVIEW_CI')
  and to_char(transdate, 'yyyy') in ('2016', '2017')
--group by trunc(transdate, 'MON'), WFTRANSACTION.transtype, ownergroup
group by trunc(transdate, 'MON'),
  rollup(case when ((wochange.ownergroup like 'LVS-%') or (wochange.ownergroup = 'VEN-INFRASTRUCTURE-PRJ')) then 'LVS' else 
    case when (wochange.ownergroup like 'TCS-%') then 'TCS' else 'ENMAX' end
  end)
--order by trunc(transdate, 'MON'), WFTRANSACTION.transtype, count(*) desc, ownergroup
order by 
  case when
    grouping(
      case when ((wochange.ownergroup like 'LVS-%') or (wochange.ownergroup = 'VEN-INFRASTRUCTURE-PRJ')) then 'LVS' else 
      case when (wochange.ownergroup like 'TCS-%') then 'TCS' else 'ENMAX' end
    end) = 1 then 'MONTH' else 'COMPANY' end desc,
  trunc(transdate, 'MON'), 
  case when ((wochange.ownergroup like 'LVS-%') or (wochange.ownergroup = 'VEN-INFRASTRUCTURE-PRJ')) then 'LVS' else 
    case when (wochange.ownergroup like 'TCS-%') then 'TCS' else 'ENMAX' end
  end
;


/*******************************************************************************
*  Change sched review stats
*******************************************************************************/

select distinct persongroup from persongroup order by persongroup;

select 
--  *
  case when
    grouping(
      case when ((wochange.ownergroup like 'LVS-%') or (wochange.ownergroup = 'VEN-INFRASTRUCTURE-PRJ')) then 'LVS' else 
      case when (wochange.ownergroup like 'TCS-%') then 'TCS' else 'ENMAX' end
    end) = 1 then 'MONTH' else 'COMPANY' end GROUP_LEVEL,

  to_char(trunc(transdate, 'MON'), 'Mon yyyy') MONTH,
  case when ((wochange.ownergroup like 'LVS-%') or (wochange.ownergroup = 'VEN-INFRASTRUCTURE-PRJ')) then 'LVS' else 
    case when (wochange.ownergroup like 'TCS-%') then 'TCS' else 'ENMAX' end
  end COMPANY,
   
  count(*) TOTAL,
  sum(case when WFTRANSACTION.transtype = 'ACCEPT' then 1 else null end) ACCEPTED,
  sum(case when WFTRANSACTION.transtype = 'REJECT' then 1 else null end) REJECTED,
  round((sum(case when WFTRANSACTION.transtype = 'ACCEPT' then 1 else null end) / count(*)) * 100, 2) ACCEPTED_PERCENT,
  round((sum(case when WFTRANSACTION.transtype = 'REJECT' then 1 else null end) / count(*)) * 100, 2) REJECTED_PERCENT
from WFTRANSACTION
  join wochange on ownerid = workorderid
where 1=1
--  and personid = 'BDENSMOR'
  and processname = 'EX_CHG'
  and nodeid in (select nodeid from wfnode where wfnode.processname = WFTRANSACTION.processname and wfnode.title = 'SCHEDULING')
  and transtype in ('ACCEPT', 'REJECT')
  and to_char(transdate, 'yyyy') = '2016'
group by trunc(transdate, 'MON'),
  rollup(case when ((wochange.ownergroup like 'LVS-%') or (wochange.ownergroup = 'VEN-INFRASTRUCTURE-PRJ')) then 'LVS' else 
    case when (wochange.ownergroup like 'TCS-%') then 'TCS' else 'ENMAX' end
  end)
--order by trunc(transdate, 'MON'), WFTRANSACTION.transtype, count(*) desc, ownergroup
order by 
  case when
    grouping(
      case when ((wochange.ownergroup like 'LVS-%') or (wochange.ownergroup = 'VEN-INFRASTRUCTURE-PRJ')) then 'LVS' else 
      case when (wochange.ownergroup like 'TCS-%') then 'TCS' else 'ENMAX' end
    end) = 1 then 'MONTH' else 'COMPANY' end desc,
  trunc(transdate, 'MON'), 
  case when ((wochange.ownergroup like 'LVS-%') or (wochange.ownergroup = 'VEN-INFRASTRUCTURE-PRJ')) then 'LVS' else 
    case when (wochange.ownergroup like 'TCS-%') then 'TCS' else 'ENMAX' end
  end,
  count(*) desc
;


/*******************************************************************************
*  Change workflow details - Time spent on tasks
*******************************************************************************/

select 
--  ACT_BY_PERSON.OWNERGROUP, count(*) CNT
  wochange.wonum, wochange.status, WOCHANGE.DESCRIPTION, WOCHANGE.PMCHGTYPE, WOCHANGE.PMCHGCAT, WOCHANGE.EX_REASONFORCHANGELIST,
  to_char(wochange.schedstart, 'dd-MON-yyyy hh24:mi:ss') schedstart, to_char(wochange.schedfinish, 'dd-MON-yyyy hh24:mi:ss') schedfinish,
  wochange.ownergroup, wochange.owner,
  case when (wfnode.TITLE like '%AUTH') then 'AUTH' else 
    case when (wfnode.title like 'SCHEDUL%') then 'SCHEDULE' else wfnode.TITLE end
  end TASK_TITLE,
  wfassignment.description ASSIGNMENT_DESCRIPTION, wfassignment.assigncode ASSIGNED_PERSON, to_char(wfassignment.startdate, 'dd-MON-yyyy hh24:mi:ss') assignment_startdate,
  to_char(wfassignment.startdate, 'DAY') assignment_start_DOW,
  to_char(WFTRANSACTION.transdate, 'dd-MON-yyyy hh24:mi:ss') assignment_completedate, 
  to_char(WFTRANSACTION.transdate, 'DAY') assignment_complete_DOW, WFTRANSACTION.memo, WFTRANSACTION.personid ACTIONED_BY_PERSON,
  ACT_BY_PERSON.OWNERGROUP ACTIONED_BY_PERSON_GROUP,
  round((WFTRANSACTION.transdate - wfassignment.startdate) * 24, 2) hours_to_action
from wochange
  join wfassignment on wochange.workorderid = wfassignment.ownerid
  join WFTRANSACTION on WFTRANSACTION.ASSIGNID = WFASSIGNMENT.ASSIGNID
  join person ACT_BY_PERSON on wftransaction.personid = ACT_BY_PERSON.personid
  join wfprocess on (WFPROCESS.PROCESSNAME = WFASSIGNMENT.PROCESSNAME and WFPROCESS.active = 1)
  join wfnode on (WFNODE.NODEID = WFASSIGNMENT.NODEID and WFNODE.PROCESSREV = WFASSIGNMENT.PROCESSREV and WFNODE.PROCESSNAME = WFASSIGNMENT.PROCESSNAME)
where wftransaction.transtype = 'WFASSIGNCOMP'
  and wochange.SCHEDFINISH >= sysdate - 60
  and wochange.status not in ('CAN')
  and (wfnode.TITLE in ('ASSESS', 'SCHEDULING', 'SCHEDULE') or wfnode.TITLE like '@%AUTH%')
  and wfassignment.description not like 'Approve or Reject Change % (CAB)'
--group by ACT_BY_PERSON.OWNERGROUP
--order by count(*) desc
order by wochange.workorderid, wochange.wonum, 
  wfassignment.assignid
;