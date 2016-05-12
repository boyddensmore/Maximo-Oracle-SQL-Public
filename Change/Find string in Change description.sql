/**************************************************************************************************************************************************************
*  Find a string in a change's description(s)
**************************************************************************************************************************************************************/

select WOCHANGE.WONUM, WOCHANGE.STATUS, CI.CINAME, WOCHANGE.OWNER, WOCHANGE.OWNERGROUP, WOCHANGE.DESCRIPTION, REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' ') LONG_DESCRIPTION, WOCHANGE.SCHEDSTART, WOCHANGE.SCHEDFINISH
from WOCHANGE
  left join CI on WOCHANGE.CINUM = CI.CINUM
  join LONGDESCRIPTION on LONGDESCRIPTION.LDKEY = WOCHANGE.WORKORDERID
where LONGDESCRIPTION.LDOWNERCOL = 'DESCRIPTION'
  and LONGDESCRIPTION.LDOWNERTABLE = 'WORKORDER'
  and WOCHANGE.STATUS = 'CLOSE'
  and WOCHANGE.SCHEDFINISH >= trunc(sysdate, 'YY')
  and WOCHANGE.SCHEDSTART <= sysdate
  and (upper(WOCHANGE.DESCRIPTION) like '%PEOPLESOFT%'
    or upper(Longdescription.Ldtext) like '%PEOPLESOFT%')
  and CI.CINAME not in ('[[CINAME]]')
;