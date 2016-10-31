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
  to_char(trunc(transdate, 'MON'), 'Mon yyyy') MONTH,
  count(*) TOTAL,
  sum(case when WFTRANSACTION.transtype = 'ACCEPT' then 1 else null end) ACCEPTED,
  sum(case when WFTRANSACTION.transtype = 'REJECT' then 1 else null end) REJECTED,
  round((sum(case when WFTRANSACTION.transtype = 'ACCEPT' then 1 else null end) / count(*)) * 100, 2) ACCEPTED_PERCENT,
  round((sum(case when WFTRANSACTION.transtype = 'REJECT' then 1 else null end) / count(*)) * 100, 2) REJECTED_PERCENT
from WFTRANSACTION
  join wochange on ownerid = workorderid
where 1=1
--  and personid = '[[PERSONID]]'
  and WFTRANSACTION.processname = 'EX_CHG'
  and WFTRANSACTION.transtype in ('ACCEPT', 'REJECT')
  and nodeid in (select nodeid from wfnode where wfnode.processname = WFTRANSACTION.processname and wfnode.title = 'REVIEW_CI')
--group by trunc(transdate, 'MON'), WFTRANSACTION.transtype, ownergroup
group by trunc(transdate, 'MON')
--order by trunc(transdate, 'MON'), WFTRANSACTION.transtype, count(*) desc, ownergroup
order by trunc(transdate, 'MON'), count(*) desc
;


/*******************************************************************************
*  Change sched review stats
*
* - Add group breakdown - ENMAX, LVS, TCS
*******************************************************************************/

select distinct persongroup from persongroup order by persongroup;

select 
--  *
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
  and processname = 'EX_CHG'
  and nodeid in (select nodeid from wfnode where wfnode.processname = WFTRANSACTION.processname and wfnode.title = 'SCHEDULING')
  and transtype in ('ACCEPT', 'REJECT')
--group by trunc(transdate, 'MON'), WFTRANSACTION.transtype, ownergroup
group by trunc(transdate, 'MON'),
  case when ((wochange.ownergroup like 'LVS-%') or (wochange.ownergroup = 'VEN-INFRASTRUCTURE-PRJ')) then 'LVS' else 
    case when (wochange.ownergroup like 'TCS-%') then 'TCS' else 'ENMAX' end
  end 
--order by trunc(transdate, 'MON'), WFTRANSACTION.transtype, count(*) desc, ownergroup
order by trunc(transdate, 'MON'), 
  case when ((wochange.ownergroup like 'LVS-%') or (wochange.ownergroup = 'VEN-INFRASTRUCTURE-PRJ')) then 'LVS' else 
    case when (wochange.ownergroup like 'TCS-%') then 'TCS' else 'ENMAX' end
  end,
  count(*) desc
;