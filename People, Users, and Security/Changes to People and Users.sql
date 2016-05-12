/*******************************************************************************
*  People who became inactive during a time period
*******************************************************************************/

select ONEDAYAGO.personid, FIVEDAYSAGO.transdatetime, FIVEDAYSAGO.status, ONEDAYAGO.transdatetime, ONEDAYAGO.status, person.DISPLAYNAME
from 
  (select personid, status, to_char(ex_transdatetime, 'dd-MON-yy hh:mm:ss') transdatetime from exiface_wdayperson where ex_transdatetime >= sysdate -1 and ex_transdatetime <= sysdate) ONEDAYAGO
  left join (select personid, status, to_char(ex_transdatetime, 'dd-MON-yy hh:mm:ss') transdatetime from exiface_wdayperson where ex_transdatetime >= sysdate -4 and ex_transdatetime <= sysdate -3) FIVEDAYSAGO
    on ONEDAYAGO.personid = FIVEDAYSAGO.personid
  left join person on person.personid = ONEDAYAGO.personid
where FIVEDAYSAGO.status = 'ACTIVE' and ONEDAYAGO.status = 'PEND_DEACTIV'
order by onedayago.personid;


/*******************************************************************************
*  All VIPs
*******************************************************************************/

select personid, VIP, status, displayname, COMPANY, EX_BUSINESSUNIT, DEPARTMENT, TITLE, SUPERVISOR, location
from person
where vip like 'VIP%'
  and status = 'ACTIVE'
order by personid;

/*******************************************************************************
*  Details of changes imported from Workday between two dates
*  For VIPs only.
*******************************************************************************/

select distinct
  FIVEDAYSAGO.personid, ONEDAYPERSON.DISPLAYNAME,
  ONEDAYPERSON.VIP,
  case when (FIVEDAYSAGO.company != ONEDAYAGO.company) then 'COMPANY' else null end
    || case when (FIVEDAYSAGO.department != ONEDAYAGO.department) then '/DEPT' else null end
    || case when (FIVEDAYSAGO.location != ONEDAYAGO.location) then '/LOCATION' else null end
    || case when (FIVEDAYSAGO.supervisor != ONEDAYAGO.supervisor) then '/SUPER' else null end
    || case when (FIVEDAYSAGO.status != ONEDAYAGO.status) then '/STATUS' else null end DELTAFIELDS,
--  FIVEDAYSAGO.transdatetime OLD_DATE,
  FIVEDAYSAGO.company OLD_COMPANY,
  FIVEDAYSAGO.department OLD_DEPT, FIVEDAYSAGO.location OLD_LOC, FIVEDAYSAGO.supervisor OLD_SUPER, FIVEDAYSAGO.status OLD_STATUS,
  '**',
--  ONEDAYAGO.transdatetime NEW_DATE,
  ONEDAYAGO.company NEW_COMPANY, 
  ONEDAYAGO.department NEW_DEPT, ONEDAYAGO.location NEW_LOC, ONEDAYAGO.supervisor NEW_SUPER, ONEDAYAGO.status NEW_STATUS
from 
  (select personid, status, company, department, location, supervisor, to_char(ex_transdatetime, 'dd-MON-yy hh:mm:ss') transdatetime from exiface_wdayperson where ex_transdatetime between sysdate -1 and sysdate) ONEDAYAGO
  left join (select personid, status, company, department, location, supervisor, to_char(ex_transdatetime, 'dd-MON-yy hh:mm:ss') transdatetime from exiface_wdayperson where ex_transdatetime between sysdate -5 and sysdate -4) FIVEDAYSAGO
    on ONEDAYAGO.personid = FIVEDAYSAGO.personid
  left join person ONEDAYPERSON on ONEDAYPERSON.personid = ONEDAYAGO.personid
where ((FIVEDAYSAGO.company != ONEDAYAGO.company)
  or (FIVEDAYSAGO.department != ONEDAYAGO.department)
  or (FIVEDAYSAGO.location != ONEDAYAGO.location)
  or (FIVEDAYSAGO.supervisor != ONEDAYAGO.supervisor)
  or (FIVEDAYSAGO.status != ONEDAYAGO.status))
  -- VIP only
  and ONEDAYPERSON.VIP like 'VIP%'
--  and ONEDAYAGO.status = 'PEND_DEACTIV'
--  and FIVEDAYSAGO.department like '33%'
order by FIVEDAYSAGO.personid
;
  
  
select *
from MAXIMO.EXIFACE_WDAYPERSON
where personid = '[[USERID]]'
order by transid desc;