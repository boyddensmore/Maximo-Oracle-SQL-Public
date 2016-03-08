/*******************************************************************************
*  This query is to feed Change details to the FSC
*******************************************************************************/


select wochange.wonum, Wochange.Description, Wochange.Owner, Wochange.Ownergroup, 
  wochange.status, WOCHANGE.PMCHGTYPE, WOCHANGE.PMCHGCAT,
  PRIMARY_TARGET.ciname,
  REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>','') LONG_DESCRIPTION,
  REGEXP_REPLACE(CHGREASON.Ldtext,'<[^>]*>','') CHGREASON, 
  PMCHGCONCERN NOT_IMPL_EFFECT,
  Wochange.Schedstart, Wochange.Schedfinish,
  Wochange.changedate,
  WORKLOGS.LOGS
from maximo.wochange
  join maximo.Longdescription on LONGDESCRIPTION.LDKEY = Wochange.Workorderid
  join maximo.Longdescription CHGREASON on CHGREASON.LDKEY = Wochange.Workorderid
  left join maximo.CI PRIMARY_TARGET on PRIMARY_TARGET.cinum = wochange.cinum
  left join
    (select 
        worklog.recordkey,
        listagg(
        'Log By: ' ||chr(9) || worklog.createby || chr(10) || 
        'Log Date: ' || chr(9) || worklog.createdate || chr(10) ||  
        'Summary: ' || chr(9) || worklog.description || chr(10) 
        || 'Details: ' || chr(10) || chr(9) || substr(REGEXP_REPLACE(WLLONGDESC.Ldtext,'<[^>]*>',''), 1, 200)
        || case when length(substr(REGEXP_REPLACE(WLLONGDESC.Ldtext,'<[^>]*>',''), 1, 200)) = 200 then chr(10) || '** LONG LOG, TRUNCATED **' else null end
        , 
      chr(10) || '---------------------------' || chr(10))
      WITHIN GROUP (order by worklog.recordkey, worklog.createdate desc) LOGS
      from maximo.worklog
        left join maximo.longdescription WLLONGDESC on (WLLONGDESC.ldownertable = 'WORKLOG' and WLLONGDESC.ldkey = WORKLOG.WORKLOGID)
      where worklog.createdate >= sysdate - 5
      group by worklog.recordkey) WORKLOGS on (worklogs.recordkey = wochange.wonum)
where Longdescription.Ldownertable = 'WORKORDER'
  and Longdescription.Ldownercol = 'DESCRIPTION'
  and CHGREASON.ldownertable = 'WORKORDER'
  and CHGREASON.Ldownercol = 'REASONFORCHANGE'
  and WOCHANGE.CHANGEDATE >= to_date(?, 'dd-mm-yyyy hh24:mi:ss')
order by Wochange.changedate desc
;



-- Testing showing only 5 worklogs

select recordkey, 
  listagg(LOGS) WITHIN GROUP (order by recordkey)
from
  (select 
    worklog.recordkey,
    rownum rnum,
    'Log By: ' ||chr(9) || worklog.createby || chr(10) || 
    'Log Date: ' || chr(9) || worklog.createdate || chr(10) ||  
    'Summary: ' || chr(9) || worklog.description || chr(10) 
    || 'Details: ' || chr(10) || chr(9) || substr(REGEXP_REPLACE(WLLONGDESC.Ldtext,'<[^>]*>',''), 1, 400)
    || case when length(substr(REGEXP_REPLACE(WLLONGDESC.Ldtext,'<[^>]*>',''), 1, 400)) = 400 then chr(10) || '** LONG LOG, TRUNCATED **' else null end
     LOGS
  from maximo.worklog
    left join maximo.longdescription WLLONGDESC on (WLLONGDESC.ldownertable = 'WORKLOG' and WLLONGDESC.ldkey = WORKLOG.WORKLOGID)
  order by worklog.createdate desc)
where rnum <= 5
group by recordkey
;
