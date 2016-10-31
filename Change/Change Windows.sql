/*******************************************************************************
*  List of changes against CIs with windows and whether or not the changes are
*  within their windows.
*******************************************************************************/

select 
/* Details (Remember the group by below) */
  
  WINDOWCHANGES.wonum, WINDOWCHANGES.status, WINDOWCHANGES.SCHEDSTART, WINDOWCHANGES.SCHEDFINISH, 
  MULTIASSETLOCCI.cinum, CI.CINAME,
  case when WINDOWDEF.calnum is not null then 'YES' else 'NO' end HAS_CHG_WINDOW,
  case when WITHINWINDOWS.calnum is not null then 'YES' else 'NO' end WITHIN_CHG_WINDOW,
  to_char(WITHINWINDOWS.STARTTIME, 'dd-Mon-yy hh24:mi:ss') starttime, to_char(WITHINWINDOWS.endtime, 'dd-Mon-yy hh24:mi:ss') endtime

/* Counts (Remember the group by below) */
--  WINDOWDEF.calnum,
--  sum(case when WINDOWDEF.calnum is not null then 1 else null end) HAS_CHG_WINDOW,
--  sum(case when OUTOFWINDOWS.calnum is not null then 1 else null end) WITHIN_CHG_WINDOW,
--  round((sum(case when OUTOFWINDOWS.calnum is not null then 1 else null end) / sum(case when WINDOWDEF.calnum is not null then 1 else null end) * 100), 1) PCT_WITHIN_WINDOW

from wochange WINDOWCHANGES
  left join MULTIASSETLOCCI on (WINDOWCHANGES.WONUM = MULTIASSETLOCCI.RECORDKEY and MULTIASSETLOCCI.recordclass = 'CHANGE')
  left join ci on MULTIASSETLOCCI.CINUM = CI.CINUM
  left join PMCHGCWCAL WINDOWDEF on (WINDOWDEF.CALNUM = CI.PMCHGCWNUM and WINDOWDEF.STARTDATE <= WINDOWCHANGES.SCHEDSTART and WINDOWDEF.ENDDATE >= WINDOWCHANGES.SCHEDFINISH)
  left join PMCHGCWTP WITHINWINDOWS on (WITHINWINDOWS.CALNUM = CI.PMCHGCWNUM and (WITHINWINDOWS.STARTTIME <= WINDOWCHANGES.SCHEDSTART and WITHINWINDOWS.ENDTIME >= WINDOWCHANGES.SCHEDFINISH))
where 1=1
  and WINDOWCHANGES.status not in ('CLOSE', 'CAN', 'FAILPIR')
  and WINDOWDEF.calnum is not null
  and WITHINWINDOWS.calnum is null
--  and wonum = 'CH-6112'
--group by WINDOWDEF.calnum
order by WITHINWINDOWS.starttime
;


/*******************************************************************************
*  Portlet - Changes against CIs with change windows, but outside of the window
*******************************************************************************/

select wonum, status
from wochange
where exists
  (select 
    WINDOWCHANGES.wonum
  from wochange WINDOWCHANGES
    left join MULTIASSETLOCCI on (WINDOWCHANGES.WONUM = MULTIASSETLOCCI.RECORDKEY and MULTIASSETLOCCI.recordclass = 'CHANGE')
    left join ci on MULTIASSETLOCCI.CINUM = CI.CINUM
    left join PMCHGCWCAL WINDOWDEF on (WINDOWDEF.CALNUM = CI.PMCHGCWNUM and WINDOWDEF.STARTDATE <= WINDOWCHANGES.SCHEDSTART and WINDOWDEF.ENDDATE >= WINDOWCHANGES.SCHEDFINISH)
    left join PMCHGCWTP WITHINWINDOWS on (WITHINWINDOWS.CALNUM = CI.PMCHGCWNUM and (WITHINWINDOWS.STARTTIME <= WINDOWCHANGES.SCHEDSTART and WITHINWINDOWS.ENDTIME >= WINDOWCHANGES.SCHEDFINISH))
  where 1=1
    and WINDOWCHANGES.status not in ('CLOSE', 'CAN', 'FAILPIR')
    and WINDOWDEF.calnum is not null
    and WITHINWINDOWS.calnum is null
    and WINDOWCHANGES.wonum = wochange.wonum)
;