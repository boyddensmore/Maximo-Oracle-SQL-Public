/*******************************************************************************
*  Instances where 
*     - An SR with open activities was closed early in error by 
*         someone outside of the Service Desk
*     - One or more affected activities was not put back into review by SD
*******************************************************************************/

select 
--  count(distinct sr.ticketid) TICKETS, count(distinct woactivity.wonum) ACTIVITIES
  ', =' || SR.TICKETID SR_TICKETID, SR.STATUS CURRENT_SR_STATUS,
  TKSTATUS.CHANGEBY TKSTATUS_CHANGEBY, TO_CHAR(TKSTATUS.CHANGEDATE, 'dd-MON-yy hh24:mi:ss') TKSTATUS_CHANGEDATE, 
  ', =' || WOACTIVITY.WONUM WOACTIVITY_WONUM, WOACTIVITY.STATUS CURRENT_WO_STATUS, WOACTIVITY.OWNERGROUP, WOACTIVITY.OWNER,
  WOSTATUS.STATUS, TO_CHAR(WOSTATUS.CHANGEDATE, 'dd-MON-yy hh24:mi:ss'), WOSTATUS.CHANGEBY
from SR
  join TKSTATUS on TKSTATUS.TICKETID = SR.TICKETID
  join WOACTIVITY on WOACTIVITY.ORIGRECORDID = SR.TICKETID
  join WOSTATUS on WOSTATUS.WONUM = WOACTIVITY.WONUM
  join CLASSSTRUCTURE on SR.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
where CLASSSTRUCTURE.CLASSIFICATIONID in ('CONTRACTOR CHANGE', 'TERMINATION', 'TRANSFER-COC', 'TRANSFER-COC', 'TRANSFER-SAME', 'ADD ACCOUNT')
  and TKSTATUS.STATUS in ('RESOLVED')
  -- Ticket was not closed by Service Desk
  and TKSTATUS.CHANGEBY not in (select RESPPARTY from PERSONGROUPTEAM where PERSONGROUP in ('SERVICE DESK'))
  -- Ticket and activity were closed at the same time by the same person
  and WOSTATUS.CHANGEBY = TKSTATUS.CHANGEBY
  and WOSTATUS.CHANGEDATE = TKSTATUS.CHANGEDATE
  -- Activity was not re-opened by SD
  and WOACTIVITY.WONUM not in (select distinct wonum from wostatus where changeby in (select RESPPARTY from PERSONGROUPTEAM where PERSONGROUP in ('SERVICE DESK')) and STATUS = 'REVIEW')
  and (
        -- Activity was not owned by the closer
        (WOACTIVITY.OWNER != WOACTIVITY.CHANGEBY and WOACTIVITY.OWNER is not null and WOACTIVITY.OWNERGROUP is null)
      or
        -- Activity was not owned by a group the closer is a member of
        (WOACTIVITY.OWNERGROUP not in (select PERSONGROUP from PERSONGROUPTEAM where RESPPARTY = WOSTATUS.CHANGEBY))
      )
  and SR.STATUS not in 'CLOSED'
  and SR.STATUS in 'RESOLVED'
  and WOACTIVITY.STATUS not in 'CLOSE'
  and TKSTATUS.CHANGEDATE >= TO_DATE('01-JUL-15 00:00:00', 'dd-MON-yy hh24:mi:ss')
--group by SR.TICKETID, TKSTATUS.CHANGEBY, TKSTATUS.CHANGEDATE
order by SR.TICKETID, TKSTATUS.CHANGEDATE desc;



/*******************************************************************************
*  Some extra validation
*******************************************************************************/
select wonum, STATUS, changeby, changedate
from wostatus
where wonum in (select wonum from wostatus where CHANGEBY in (select RESPPARTY from PERSONGROUPTEAM where PERSONGROUP in ('SERVICE DESK'))
                and status not in ('COMP', 'CLOSE'))
  and WOSTATUS.WONUM in
    (select distinct WOSTATUS.WONUM
--  SR.TICKETID SR_TICKETID,
--  TKSTATUS.CHANGEBY TKSTATUS_CHANGEBY, TKSTATUS.CHANGEDATE TKSTATUS_CHANGEDATE, 
--  WOACTIVITY.WONUM, WOACTIVITY.OWNERGROUP, WOACTIVITY.OWNER,
--  WOSTATUS.STATUS, WOSTATUS.CHANGEDATE, WOSTATUS.CHANGEBY
--  count(*) TASKS_CLOSED
--  WOSTATUS.CHANGEBY WOSTATUS_CHANGEBY, WOSTATUS.STATUS WOSTATUS_STATUS, WOSTATUS.CHANGEDATE WOSTATUS_CHANGEDATE
from SR
  join TKSTATUS on TKSTATUS.TICKETID = SR.TICKETID
  join WOACTIVITY on WOACTIVITY.ORIGRECORDID = SR.TICKETID
  join WOSTATUS on WOSTATUS.WONUM = WOACTIVITY.WONUM
where SR.CLASSSTRUCTUREID in 
      (select classstructureid from MAXIMO.CLASSSTRUCTURE where CLASSIFICATIONID in ('CONTRACTOR CHANGE', 'TERMINATION', 'TRANSFER-COC', 'TRANSFER-COC', 'TRANSFER-SAME'))
  and TKSTATUS.STATUS = 'RESOLVED'
  and TKSTATUS.CHANGEBY not in 
    (select RESPPARTY from PERSONGROUPTEAM where PERSONGROUP in ('SERVICE DESK'))
  and WOSTATUS.CHANGEBY = TKSTATUS.CHANGEBY
  and WOSTATUS.CHANGEDATE = TKSTATUS.CHANGEDATE)
order by wonum, changedate;


/*******************************************************************************
*  Portlet query
*******************************************************************************/


select distinct SR.TICKETID
from SR
  join TKSTATUS on TKSTATUS.TICKETID = SR.TICKETID
  join WOACTIVITY on WOACTIVITY.ORIGRECORDID = SR.TICKETID
  join WOSTATUS on WOSTATUS.WONUM = WOACTIVITY.WONUM
  join CLASSSTRUCTURE on SR.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
where CLASSSTRUCTURE.CLASSIFICATIONID in ('CONTRACTOR CHANGE', 'TERMINATION', 'TRANSFER-COC', 'TRANSFER-COC', 'TRANSFER-SAME', 'ADD ACCOUNT')
  and TKSTATUS.STATUS in ('RESOLVED')
  and TKSTATUS.CHANGEBY not in (select RESPPARTY from PERSONGROUPTEAM where PERSONGROUP in ('SERVICE DESK'))
  and WOSTATUS.CHANGEBY = TKSTATUS.CHANGEBY
  and WOSTATUS.CHANGEDATE = TKSTATUS.CHANGEDATE
  and WOACTIVITY.WONUM not in (select distinct wonum from wostatus where changeby in (select RESPPARTY from PERSONGROUPTEAM where PERSONGROUP in ('SERVICE DESK')) and STATUS = 'REVIEW')
  and (
        (WOACTIVITY.OWNER != WOACTIVITY.CHANGEBY and WOACTIVITY.OWNER is not null and WOACTIVITY.OWNERGROUP is null)
      or
        (WOACTIVITY.OWNERGROUP not in (select PERSONGROUP from PERSONGROUPTEAM where RESPPARTY = WOSTATUS.CHANGEBY))
      )
  and SR.STATUS not in 'CLOSED'
  and WOACTIVITY.STATUS not in 'CLOSE';