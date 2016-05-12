select WFASSIGNMENT.WFASSIGNMENTID, WOCHANGE.WONUM, WOCHANGE.STATUS, WOCHANGE.DESCRIPTION CHANGE_DESC, 
  WOCHANGE.PMCHGTYPE, WOCHANGE.PMCHGCAT,
  WFASSIGNMENT.DESCRIPTION ASSGN_DESC, WFASSIGNMENT.ASSIGNSTATUS, 
  WFASSIGNMENT.ORIGPERSON, WFASSIGNMENT.ASSIGNCODE,
  CASE WHEN assigncode not in (select distinct respparty from persongroupteam) THEN 'NO' ELSE 'YES' END IN_PERSON_GROUP,
  CASE WHEN assigncode not in (select userid from groupuser where groupname = 'CHGANL') THEN 'NO' ELSE 'YES' END IN_CHGANL,
  WOCHANGE.SCHEDSTART, WOCHANGE.SCHEDFINISH
from WFASSIGNMENT
  join WOCHANGE on WFASSIGNMENT.OWNERID = WOCHANGE.WORKORDERID
where WFASSIGNMENT.APP = 'CHANGE'
  and WFASSIGNMENT.ASSIGNSTATUS not in ('COMPLETE', 'FORWARDED', 'INACTIVE')
  and WOCHANGE.STATUS not in ('COMP', 'REVIEW', 'IMPL', 'INPRG')
--  and WFASSIGNMENT.ASSIGNCODE in ('[[USERNAME]]')
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


