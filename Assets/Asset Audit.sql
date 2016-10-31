/*******************************************************************************
* Data Quality Checks to build
* - Cases where user and custodian orgs differ
* - Assets that shouldn't have CIs but do
* - 
* - 
* - 
*******************************************************************************/


/*******************************************************************************
*  Workstations with no owner
*******************************************************************************/

SELECT asset.assetnum, asset.description, asset.classstructureid,
        asset.status, asset.manufacturer, asset.ex_model, asset.ex_other,
        asset.assettag, asset.serialnum, asset.LOCATION,
        locations.description location_description
FROM asset
  JOIN locations ON asset.LOCATION = locations.LOCATION
WHERE asset.assetnum NOT IN
  (SELECT assetusercust.assetnum
  FROM assetusercust
  WHERE (assetusercust.isuser = 1 OR assetusercust.iscustodian = 1))
AND asset.status IN ('DEPLOYED', 'IN STOCK')
-- Only show workstations
AND (asset.classstructureid IN ('1238', '1243')
    OR upper(asset.ex_model) LIKE '%SURFACE%')
ORDER BY assetnum;


/*******************************************************************************
*  Assets with no owner or custodian
*******************************************************************************/

SELECT classstructure.classificationid, count(*)
FROM asset
  JOIN locations ON asset.LOCATION = locations.LOCATION
  join classstructure on classstructure.classstructureid = asset.classstructureid
WHERE asset.assetnum NOT IN
  (SELECT assetusercust.assetnum
  FROM assetusercust
  WHERE (assetusercust.isuser = 1 OR assetusercust.iscustodian = 1))
AND asset.status IN ('DEPLOYED', 'IN STOCK')
and asset.classstructureid in (select classstructureid
                                from classstructure
                                where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                                  and (upper(description) like '%DESKTOP%'
                                    or upper(description) like '%LAPTOP%'
                                    or upper(description) like '%TABLET%'
                                    or upper(description) like '%SMART PHONE%'
                                    or upper(description) like '%MOBILE PHONE%'))
group by classstructure.classificationid;

/*******************************************************************************
*  Workstations with no owner, but with tickets logged against them
*******************************************************************************/

SELECT asset.assetnum, asset.classstructureid,
        asset.assettag, asset.LOCATION, 
        locations.description LOCATION_DESCRIPTION, ticketid, TICKET.AFFECTEDPERSON, PERSON.STATUS, PERSON.STATUSDATE
FROM asset
  JOIN locations ON asset.LOCATION = locations.LOCATION
  join ticket on (TICKET.ASSETNUM = ASSET.ASSETNUM and ticket.reportdate >= sysdate - 90)
  join person on PERSON.PERSONID = TICKET.AFFECTEDPERSON
WHERE asset.assetnum NOT IN
  (SELECT assetusercust.assetnum
  FROM assetusercust
  WHERE (assetusercust.isuser = 1 OR assetusercust.iscustodian = 1))
AND asset.status IN ('DEPLOYED', 'IN STOCK')
-- Only show workstations
AND (asset.classstructureid IN ('1238', '1243')
    OR upper(asset.ex_model) LIKE '%SURFACE%')
ORDER BY assetnum;


/*******************************************************************************
*  Comparison of asset users and tickets
*******************************************************************************/

select ASSET.ASSETNUM, ASSET.ASSETTAG, CLASSSTRUCTURE.CLASSIFICATIONID,
  TICKET.TICKETID, TICKET.REPORTDATE, TICKET.AFFECTEDPERSON,
  ASSETLOCUSERCUST.PERSONID ASSET_PERSON,
  CASE WHEN (TICKET.AFFECTEDPERSON = ASSETLOCUSERCUST.PERSONID) THEN 'YES' ELSE 'NO' END TK_ASSET_PERS_MATCH,
  TICKET.LOCATION TICKET_LOC,
  AFF_PERSON.LOCATION AFF_PERSON_LOC,
  ASSET.LOCATION ASSET_LOC,
  ASSET_PERSON.LOCATION ASSET_PERSON_LOC,
  CASE WHEN (AFF_PERSON.LOCATION = ASSET.LOCATION and AFF_PERSON.LOCATION = ASSET_PERSON.LOCATION) THEN 'MATCH' ELSE 'DISCREPANCY' END LOC_MATCH,
  ASSETLOCUSERCUST.ISUSER, ASSETLOCUSERCUST.ISCUSTODIAN, ASSETLOCUSERCUST.ISPRIMARY,
  TICKET.DESCRIPTION
from ASSET
  join TICKET on TICKET.ASSETNUM = ASSET.ASSETNUM
  join PERSON AFF_PERSON on AFF_PERSON.PERSONID = TICKET.AFFECTEDPERSON
  join CLASSSTRUCTURE on CLASSSTRUCTURE.CLASSSTRUCTUREID = ASSET.CLASSSTRUCTUREID
  LEFT join ASSETLOCUSERCUST on ASSETLOCUSERCUST.ASSETNUM = ASSET.ASSETNUM
  LEFT join PERSON ASSET_PERSON on ASSET_PERSON.PERSONID = ASSETLOCUSERCUST.PERSONID
where TICKET.ASSETNUM is not null
  and CLASSSTRUCTURE.CLASSIFICATIONID in ('DESKTOP', 'LAPTOP')
  and (TICKET.AFFECTEDPERSON = ASSETLOCUSERCUST.PERSONID or ASSETLOCUSERCUST.PERSONID is null)
-- TEST ------------------------------------------------------------------------------
--and ASSETLOCUSERCUST.PERSONID is null
and (TICKET.REPORTDATE >= sysdate - 30 or TICKET.REPORTDATE is null)
order by TICKET.REPORTDATE desc, ASSET.ASSETNUM, TICKET.TICKETID;


/*******************************************************************************
*  Assets with more than one Custodian
*******************************************************************************/

select *
from
  (select asset.assetnum, count(*) CUSTODIANS
  from ASSET
    join ASSETUSERCUST ASSETUSER on (ASSETUSER.ASSETNUM = ASSET.ASSETNUM and ASSETUSER.ISCUSTODIAN = 1)
    join classstructure on classstructure.classstructureid = asset.classstructureid
  where asset.classstructureid in (select classstructureid
                                  from classstructure
                                  where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                                    and (upper(description) like '%DESKTOP%'
                                      or upper(description) like '%LAPTOP%'
                                      or upper(description) like '%TABLET%'
                                      or upper(description) like '%SMART PHONE%'
                                      or upper(description) like '%MOBILE PHONE%'))
  group by asset.assetnum) CUST_CNT
where CUST_CNT.custodians > 1
;


/*******************************************************************************
*  Assets with more than one User
*******************************************************************************/

select *
from
(select asset.assetnum, count(*) USER_err_COUNT
  from ASSET
    join ASSETUSERCUST ASSETUSER on (ASSETUSER.ASSETNUM = ASSET.ASSETNUM and ASSETUSER.ISUSER = 1)
    join classstructure on classstructure.classstructureid = asset.classstructureid
  where asset.classstructureid in (select classstructureid
                                  from classstructure
                                  where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                                    and (upper(description) like '%DESKTOP%'
                                      or upper(description) like '%LAPTOP%'
                                      or upper(description) like '%TABLET%'
                                      or upper(description) like '%SMART PHONE%'
                                      or upper(description) like '%MOBILE PHONE%'))
  group by asset.assetnum) USR_CNT
where USR_CNT.USER_err_COUNT > 1;


/*******************************************************************************
*  Assets with more than one Custodian
*******************************************************************************/

select ASSET.ASSETNUM, count(*)
from ASSET
  join ASSETUSERCUST ASSETCUST on (ASSETCUST.ASSETNUM = ASSET.ASSETNUM and ASSETCUST.ISCUSTODIAN = 1)
where asset.classstructureid in (select classstructureid
                                from classstructure
                                where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                                  and (upper(description) like '%DESKTOP%'
                                    or upper(description) like '%LAPTOP%'
                                    or upper(description) like '%TABLET%'
                                    or upper(description) like '%SMART PHONE%'
                                    or upper(description) like '%MOBILE PHONE%'))
group by ASSET.ASSETNUM
order by count(*) desc;


/*******************************************************************************
*  People with null Company, BU, and Dept
*******************************************************************************/

select
  (select count(*) from person where status = 'ACTIVE' and company is null and EX_BUSINESSUNIT is null and DEPARTMENT is null) C_B_D,
  (select count(*) from person where status = 'ACTIVE' and COMPANY is null and EX_BUSINESSUNIT is null) C_B,
  (select count(*) from person where status = 'ACTIVE' and DEPARTMENT is null and EX_BUSINESSUNIT is null) D_B,
  (select count(*) from person where status = 'ACTIVE' and COMPANY is null and DEPARTMENT is null) C_D,
  (select count(*) from person where status = 'ACTIVE' and COMPANY is null) COMPANY,
  (select count(*) from person where status = 'ACTIVE' and DEPARTMENT is null) DEPARTMENT,
  (select count(*) from person where status = 'ACTIVE' and EX_BUSINESSUNIT is null) BU
from Dual;


/*******************************************************************************
*  Counts of assets with users with no Company, BU, Dept
*******************************************************************************/

SELECT person.company, person.EX_BUSINESSUNIT, person.department, person.deptdesc, count(asset.assetnum)
FROM asset
  LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
  LEFT JOIN person ON person.personid = assetusercust.personid
WHERE asset.classstructureid in (select classstructureid
                                from classstructure
                                where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                                  and (upper(description) like '%DESKTOP%'
                                    or upper(description) like '%LAPTOP%'
                                    or upper(description) like '%TABLET%'
                                    or upper(description) like '%SMART PHONE%'
                                    or upper(description) like '%MOBILE PHONE%'))
  AND asset.status IN ('DEPLOYED', 'IN STOCK')
  and (person.PERSONID in (select personid from person where DEPARTMENT is null)
    or person.personid in (select personid from person where EX_BUSINESSUNIT is null)
    or person.personid in (select personid from person where COMPANY is null))
GROUP BY person.company, person.EX_BUSINESSUNIT, person.department, person.deptdesc
ORDER BY count(asset.assetnum) DESC;

/*******************************************************************************
*  Details of assets with users with no Company, BU, Dept
*******************************************************************************/

SELECT distinct ',='||asset.assetnum assetnum, asset.assettag, 
  person.PERSONID, --person.FIRSTNAME, person.LASTNAME, 'IT-IS', 
  person.DISPLAYNAME, person.company, person.EX_BUSINESSUNIT, person.department, person.STATUS, person.SUPERVISOR, --'', 0,
--  person.deptdesc, 
  super.status SUPER_STATUS
FROM asset
  LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
  LEFT JOIN person ON person.personid = assetusercust.personid
  left join person super on person.supervisor = super.personid
WHERE asset.classstructureid in (select classstructureid
                                from classstructure
                                where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                                  and (upper(description) like '%DESKTOP%'
                                    or upper(description) like '%LAPTOP%'
                                    or upper(description) like '%TABLET%'
                                    or upper(description) like '%SMART PHONE%'
                                    or upper(description) like '%MOBILE PHONE%'))
  AND asset.status IN ('DEPLOYED', 'IN STOCK')
  and (person.PERSONID in (select personid from person where DEPARTMENT is null)
    or person.personid in (select personid from person where EX_BUSINESSUNIT is null)
    or person.personid in (select personid from person where COMPANY is null))
order by assetnum;



/*******************************************************************************
*  Asset users and custodians with invalid Company / BU combination.
*  Only include people on active assets.
*******************************************************************************/

select personid, FIRSTNAME, LASTNAME, 'IT-IS', displayname, status,
  (select count(*) from assetlocusercust join asset on ASSETLOCUSERCUST.ASSETNUM = ASSET.ASSETNUM where ASSET.STATUS not in ('MISSING', 'DECOMMISSIONED', 'DISPOSED') and PERSON.PERSONID = ASSETLOCUSERCUST.PERSONID) ASSET_COUNT,
  company, ex_businessunit, department, deptdesc
from person
where personid in (select personid from assetlocusercust join asset on ASSETLOCUSERCUST.ASSETNUM = ASSET.ASSETNUM where ASSET.STATUS not in ('MISSING', 'DECOMMISSIONED', 'DISPOSED'))
  and ((not (company = 'ENM ENMAX Corporation' and (ex_businessunit in ('ENMAX Energy Corporation', 'ENMAX Power Services Corp.', 'ENMAX Encompass Inc.', 'ENMAX Corporation') or ex_businessunit is null))
  and not (company = 'EPC ENMAX Power Corporation' and (ex_businessunit in ('ENMAX Power Corporation') or ex_businessunit is null))) or company is null or ex_businessunit is null)
;

/*******************************************************************************
*  Assets with inactive users or custodians
*******************************************************************************/

SELECT ',='||asset.assetnum, asset.assetnum, asset.assettag, asset.status,
  asset.changeby, ASSET.CHANGEDATE,
  assetuser.personid usr, assetcustodian.personid custodian,
  CASE WHEN assetcustodian.personid IS NULL THEN CASE WHEN assetuser.personid IS NULL THEN 'NO USER OR CUST' ELSE 'USER' END ELSE 'CUSTODIAN' END usercust_record_used,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.personid ELSE assetcustodian.personid END selected_person,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.displayname ELSE assetcustodian.displayname END selected_person_displayname,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.status ELSE assetcustodian.status END selected_person_status,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.supervisor ELSE assetcustodian.supervisor END selected_person_supervisor,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.company ELSE assetcustodian.company END selected_company,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.ex_businessunit ELSE assetcustodian.ex_businessunit END selected_businessunit,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.department ELSE assetcustodian.department END selected_department,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.deptdesc ELSE assetcustodian.deptdesc END selected_deptdesc
FROM asset
  JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  LEFT JOIN
  (SELECT asset.assetnum, person.personid, person.displayname, person.company, person.ex_businessunit, person.department, person.deptdesc, person.status, person.supervisor, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
  WHERE assetusercust.iscustodian = 1
  ORDER BY asset.assetnum) assetcustodian ON assetcustodian.assetnum = asset.assetnum
  LEFT JOIN
  (SELECT asset.assetnum,person.personid, person.displayname, person.company, person.ex_businessunit, person.department, person.deptdesc, person.status, person.supervisor, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
  WHERE assetusercust.isuser = 1
  ORDER BY asset.assetnum) assetuser ON assetuser.assetnum = asset.assetnum
WHERE asset.classstructureid in (select classstructureid
                                from classstructure
                                where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                                  and (upper(description) like '%DESKTOP%'
                                    or upper(description) like '%LAPTOP%'
                                    or upper(description) like '%TABLET%'
                                    or upper(description) like '%SMART PHONE%'
                                    or upper(description) like '%MOBILE PHONE%'))
  AND asset.status IN ('DEPLOYED', 'IN STOCK')
  and CASE WHEN assetcustodian.personid IS NULL THEN assetuser.status ELSE assetcustodian.status END = 'PEND_DEACTIV'
ORDER BY CASE WHEN assetcustodian.personid IS NULL THEN assetuser.supervisor ELSE assetcustodian.supervisor END, asset.assetnum;


/*******************************************************************************
*  Assets with inactive users, by count of users on that asset
*******************************************************************************/

select ASSETLOCUSERCUST.ASSETNUM, CLASSSTRUCTURE.CLASSIFICATIONID, count(*)
from ASSETLOCUSERCUST
  join asset on ASSETLOCUSERCUST.ASSETNUM = asset.ASSETNUM
  join CLASSSTRUCTURE on CLASSSTRUCTURE.CLASSSTRUCTUREID = ASSET.CLASSSTRUCTUREID
where asset.ASSETNUM in
  (select distinct assetnum
  from ASSETLOCUSERCUST
    join person on person.PERSONID = ASSETLOCUSERCUST.PERSONID
  where person.STATUS != 'ACTIVE')
  and asset.STATUS not in ('DECOMMISSIONED', 'DISPOSED')
group by ASSETLOCUSERCUST.ASSETNUM, CLASSSTRUCTURE.CLASSIFICATIONID
order by count(*) desc;


/*******************************************************************************
*  Assets assigned to Deskside
*******************************************************************************/

SELECT ',='||asset.assetnum, asset.assetnum, asset.assettag, asset.status,
  asset.changeby, ASSET.CHANGEDATE,
  assetuser.personid usr, assetcustodian.personid custodian
FROM asset
  JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  LEFT JOIN
  (SELECT asset.assetnum, person.personid, person.displayname, person.company, person.ex_businessunit, person.department, person.deptdesc, person.status, person.supervisor, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
  WHERE assetusercust.iscustodian = 1
  ORDER BY asset.assetnum) assetcustodian ON assetcustodian.assetnum = asset.assetnum
  LEFT JOIN
  (SELECT asset.assetnum,person.personid, person.displayname, person.company, person.ex_businessunit, person.department, person.deptdesc, person.status, person.supervisor, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
  WHERE assetusercust.isuser = 1
  ORDER BY asset.assetnum) assetuser ON assetuser.assetnum = asset.assetnum
WHERE asset.classstructureid in (select classstructureid
                                from classstructure
                                where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                                  and (upper(description) like '%DESKTOP%'
                                    or upper(description) like '%LAPTOP%'
                                    or upper(description) like '%TABLET%'
                                    or upper(description) like '%SMART PHONE%'
                                    or upper(description) like '%MOBILE PHONE%'))
  AND asset.status IN ('DEPLOYED', 'IN STOCK')
  and (assetuser.personid = 'DESKSIDE' or assetcustodian.personid = 'DESKSIDE')
ORDER BY assettag;


/*******************************************************************************
*  Count of workstations by status
*******************************************************************************/

SELECT status, count(*)
FROM asset
--WHERE (asset.classstructureid IN ('1238', '1243')
--    OR upper(asset.ex_model) LIKE '%SURFACE%')
GROUP BY status
ORDER BY count(*) DESC;


/*******************************************************************************
*  Unclassified assets
*******************************************************************************/

SELECT ',='||asset.assetnum, asset.assetnum, asset.DESCRIPTION, asset.assettag, asset.status,
  asset.changedate, asset.changeby, PERSON.displayname, PERSON.TITLE, PERSON.SUPERVISOR
FROM asset
  join person on PERSON.PERSONID = ASSET.CHANGEBY
WHERE asset.classstructureid IS NULL
  and asset.status not in ('DECOMMISSIONED', 'DISPOSED')
ORDER BY asset.changeby, asset.changedate desc;


/*******************************************************************************
*  Misclassified assets
*******************************************************************************/


select asset.classstructureid, CLASSSTRUCTURE.CLASSIFICATIONID, CLASSSTRUCTURE.DESCRIPTION, ASSET.DESCRIPTION, count(*)
from asset
  join CLASSSTRUCTURE on CLASSSTRUCTURE.CLASSSTRUCTUREID = ASSET.CLASSSTRUCTUREID
where ASSET.STATUS in ('IN STOCK', 'DEPLOYED')
group by asset.classstructureid, CLASSSTRUCTURE.CLASSIFICATIONID, CLASSSTRUCTURE.DESCRIPTION, ASSET.DESCRIPTION
order by CLASSSTRUCTURE.CLASSIFICATIONID, count(*) desc;

select ',='||assetnum, assetnum, assettag, CLASSSTRUCTURE.CLASSIFICATIONID, ASSET.DESCRIPTION, ASSET.ITEMNUM
from asset
  join CLASSSTRUCTURE on CLASSSTRUCTURE.CLASSSTRUCTUREID = ASSET.CLASSSTRUCTUREID
where ASSET.STATUS in ('IN STOCK', 'DEPLOYED')
  and CLASSSTRUCTURE.CLASSIFICATIONID = 'DESKTOP'
  and ASSET.DESCRIPTION != 'Computer, Desktop';

/*******************************************************************************
*  Changes to Assetspecs
*******************************************************************************/

select assetnum, assetattrid, alnvalue, NUMVALUE, changeby, changedate, createddate, removeddate
from ASSETSPECHIST
where 1=1
--  and assetnum in (select assetnum from assetspechist where changeby = 'BDENSMOR' and changedate >= sysdate - 1)
  and assetnum = '2971' 
order by assetnum, assetattrid
;

/*******************************************************************************
*  Potentially invalid classifications
*******************************************************************************/

--Details
select ',='||asset.assetnum, asset.assetnum, asset.assettag, asset.description, 
  CLASSSTRUCTURE.CLASSIFICATIONID, asset.CHANGEBY, asset.CHANGEDATE
from asset
  left join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = asset.CLASSSTRUCTUREID
where CLASSSTRUCTURE.CLASSIFICATIONID not in 
  ('DESKTOP', 'PHYSSERV', 'CONFPHONE', 'PROJECTORSYS', 'VIRTDESKTOP', 'FAX', 'UPS', 
  'PRINTER', 'TABLET', 'ROUTER', 'SWITCH', 'TAPESYS', 'DESKPHONE', 'PDU', 'PBX', 'NAS', 
  'LAPTOP', 'SMARTPHONE', 'MOBILEDATA', 'MOBILEPHONE', 'SECDEV');

--Count
select CLASSSTRUCTURE.CLASSIFICATIONID, count(*)
from asset
  left join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = asset.CLASSSTRUCTUREID
where CLASSSTRUCTURE.CLASSIFICATIONID not in 
  ('DESKTOP', 'PHYSSERV', 'CONFPHONE', 'PROJECTORSYS', 'VIRTDESKTOP', 'FAX', 'UPS', 
  'PRINTER', 'TABLET', 'ROUTER', 'SWITCH', 'TAPESYS', 'DESKPHONE', 'PDU', 'PBX', 'NAS', 
  'LAPTOP', 'SMARTPHONE', 'MOBILEDATA', 'MOBILEPHONE', 'SECDEV')
group by CLASSSTRUCTURE.CLASSIFICATIONID;

/*******************************************************************************
*  Assets with no description
*******************************************************************************/

select ',='||asset.assetnum, asset.assettag, asset.description, asset.changeby, asset.changedate, CLASSSTRUCTURE.CLASSIFICATIONID
from asset
  join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = ASSET.CLASSSTRUCTUREID
where asset.description is null
order by CLASSSTRUCTURE.CLASSIFICATIONID;


/*******************************************************************************
*  Deskside classstructures
*******************************************************************************/
select classstructureid
from classstructure
where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
  and (upper(description) like '%DESKTOP%'
    or upper(description) like '%LAPTOP%'
    or upper(description) like '%TABLET%'
    or upper(description) like '%PHONE%');


/*******************************************************************************
*  Deskside/Telephony assetspec completion by classification
*******************************************************************************/
select classstructure.classificationid, ASSETSPEC.ASSETATTRID, 
  count(*) TOTAL,
  count(case when assetspec.alnvalue is not null then 'COMPLETE' else null end) COMPLETED_COUNT, 
  count(case when assetspec.alnvalue is null then 'NOTCOMPLETE' else null end) NOTCOMPLETED_COUNT, 
  round(count(case when assetspec.alnvalue is not null then 'COMPLETE' else null end) /count(*) * 100, 2) COMPLETED_PCT, 
  round(count(case when assetspec.alnvalue is null then 'NOTCOMPLETE' else null end) /count(*) * 100, 2) NOTCOMPLETED_PCT
from asset
  join classstructure on classstructure.classstructureid = asset.classstructureid
  join assetspec on assetspec.assetnum = asset.assetnum
where asset.classstructureid in (select classstructureid
                                from classstructure
                                where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                                  and (upper(description) like '%DESKTOP%'
                                    or upper(description) like '%LAPTOP%'
                                    or upper(description) like '%TABLET%'
                                    or upper(description) like '%PHONE%'))
group by classstructure.classificationid, ASSETSPEC.ASSETATTRID
order by classstructure.classificationid, ASSETSPEC.ASSETATTRID;


/*******************************************************************************
*  Deskside base value completion by classification
*******************************************************************************/
select classstructure.classificationid, count(*) TOTALASSETS,
  count(case when manufacturer is null then 'INCOMPLETE' else null end) MANUFACTURER_INCOMPLETE,
  count(case when ex_model is null then 'INCOMPLETE' else null end) MODEL_INCOMPLETE,
  count(case when serialnum is null then 'INCOMPLETE' else null end) SERIAL_INCOMPLETE,
  count(case when location in (select location from locations where classstructureid in ('1308', '1306', '1309')) then 'INCOMPLETE' else null end) LOCATION_INCOMPLETE
from asset
  join classstructure on classstructure.classstructureid = asset.classstructureid
where asset.classstructureid in (select classstructureid
                                from classstructure
                                where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                                  and (upper(description) like '%DESKTOP%'
                                    or upper(description) like '%LAPTOP%'
                                    or upper(description) like '%TABLET%'
                                    or upper(description) like '%SMART PHONE%'
                                    or upper(description) like '%MOBILE PHONE%'))
  and status in ('IN STOCK', 'DEPLOYED')
group by classstructure.classificationid;


/*******************************************************************************
*  Assets with possibly invalid location
*******************************************************************************/

select asset.assetnum, asset.assettag, locations.location, CLASSSTRUCTURE.CLASSIFICATIONID LOC_CLASS
from asset
  join locations on LOCATIONS.location = ASSET.location
  left join classstructure on LOCATIONS.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
where exists (select 1
              from classstructure
              where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                and (upper(description) like '%DESKTOP%'
                  or upper(description) like '%LAPTOP%'
                  or upper(description) like '%TABLET%'
                  or upper(description) like '%SMART PHONE%'
                  or upper(description) like '%MOBILE PHONE%')
              and asset.classstructureid = classstructureid)
  and (CLASSSTRUCTURE.CLASSIFICATIONID is null 
      or CLASSSTRUCTURE.CLASSIFICATIONID not in ('IT EQUIPMENT', 'DESK', 'ROOM'))
  and ASSET.location != 'MOBILEDEVICE'
;

/*******************************************************************************
*  Unclassified locations
*******************************************************************************/

select ',='||locations.location, locations.location, LOCATIONS.DESCRIPTION, locations.status, CLASSSTRUCTURE.CLASSIFICATIONID LOC_CLASS,
  (select count(*) from person where person.location = locations.location and person.status = 'ACTIVE') PERSON_COUNT,
  (select count(*) from asset where asset.location = locations.location and asset.status not in ('DISPOSED', 'DECOMMISSIONED')) ASSET_COUNT
from locations
  left join classstructure on LOCATIONS.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
where CLASSSTRUCTURE.CLASSIFICATIONID is null
--  and LOCATIONS.STATUS not in ('OPERATING', 'DEPLOYED')
;

/*******************************************************************************
*  Assets with duplicate asset tag or serial numbers
*******************************************************************************/

select *
from
  (select 
    ',='|| assetnum AN,
    assetnum,
    assettag,
    EX_OTHER,
    serialnum,
    classpath.classpath,
    CHANGEBY,
    CHANGEDATE,
    status,
    (select count(*) from asset DUPASSET where DUPASSET.assettag = PRIMEASSET.assettag) DUP_ASSETTAGS,
    case when (select count(*) from asset DUPASSET where DUPASSET.assettag = PRIMEASSET.assettag) > 1 then 
      (select LISTAGG(asset.assetnum, ', ') within group (order by PRIMEASSET.assettag) from asset where asset.assettag = PRIMEASSET.assettag group by assettag)
      else null end ASSETTAG_DUP_ASSETNUMS,
    (select count(*) from asset DUPASSET where DUPASSET.SERIALNUM = PRIMEASSET.SERIALNUM) DUP_SERIAL,
    case when (select count(*) from asset DUPASSET where DUPASSET.SERIALNUM = PRIMEASSET.SERIALNUM) > 1 then 
      (select LISTAGG(asset.assetnum, ', ') within group (order by PRIMEASSET.serialnum) from asset where asset.serialnum = PRIMEASSET.serialnum group by serialnum)
      else null end SERIALNUM_DUP_ASSETNUMS
  from asset PRIMEASSET
    join (select classstructureid, LISTAGG(ANCESTORCLASSID, ' \ ') within group (order by hierarchylevels desc) as CLASSPATH from CLASSANCESTOR group by classstructureid) CLASSPATH on CLASSPATH.CLASSstructureid = PRIMEASSET.CLASSSTRUCTUREID
  where
    status = 'DEPLOYED'
--    and PRIMEASSET.CLASSSTRUCTUREID in ('1123', '1238', '1147', '1243', '1206', '1241', '1120', '1121', '1178', '1279')
  )
where ((DUP_ASSETTAGS > 1 and assettag is not null)
  or (DUP_SERIAL > 1 and serialnum is not null))
order by assettag;


/*******************************************************************************
*  All Deskside asset data
*******************************************************************************/

SELECT asset.assetuid, asset.assetnum, asset.assettag, asset.status, asset.serialnum, asset.LOCATION, LOCATIONS.DESCRIPTION LOC_DESC, 
  LOCCLASS.CLASSIFICATIONID LOCATION_CLASS, classstructure.classificationid ASSET_CLASS, asset.manufacturer, asset.ex_model, 
  asset.ex_other, assetuser.personid usr, ASSETUSER.SUPERVISOR usr_super, assetcustodian.personid custodian, ASSETCUSTODIAN.SUPERVISOR cust_super,
  CASE WHEN assetcustodian.personid IS NULL THEN CASE WHEN assetuser.personid IS NULL THEN 'NO USER OR CUST' ELSE 'USER' END ELSE 'CUSTODIAN' END usercust_record_used,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.personid ELSE assetcustodian.personid END selected_person,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.status ELSE assetcustodian.status END selected_person_status,
  case when asset.manufacturer is null then 'INCOMPLETE' else null end MANUFACTURER_INCOMPLETE,
  case when asset.ex_model is null then 'INCOMPLETE' else null end MODEL_INCOMPLETE,
  case when asset.serialnum is null then 'INCOMPLETE' else null end SERIAL_INCOMPLETE,
  case when asset.location in (select location from locations where classstructureid in ('1308', '1306', '1309')) then 'INCOMPLETE' else null end LOCATION_INCOMPLETE
FROM asset
  JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  join locations on LOCATIONS.LOCATION = ASSET.LOCATION
  left join CLASSSTRUCTURE LOCCLASS on LOCATIONS.CLASSSTRUCTUREID = LOCCLASS.CLASSSTRUCTUREID
  LEFT JOIN
  (SELECT asset.assetnum, person.personid, person.company, person.ex_businessunit, person.department, person.deptdesc, PERSON.SUPERVISOR, person.status, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
    JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  WHERE assetusercust.iscustodian = 1
  ORDER BY asset.assetnum) assetcustodian ON assetcustodian.assetnum = asset.assetnum
  LEFT JOIN
  (SELECT asset.assetnum,person.personid, person.company, person.ex_businessunit, person.department, person.deptdesc, PERSON.SUPERVISOR, person.status, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
    JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  WHERE assetusercust.isuser = 1
  ORDER BY asset.assetnum) assetuser ON assetuser.assetnum = asset.assetnum
WHERE exists
        (select *
        from classancestor
        where exists (select *
                      from classstructure 
                      where exists 
                        (select classstructureid 
                          from MAXIMO.classusewith 
                          where objectvalue = 'ASSET' 
                            and classusewith.classstructureid = classstructure.classstructureid)
                        and classificationid in ('MOBILE', 'DESKTOP', 'MOBILEPHONE', 'MOBILEDATA', 'AUDIOVISUAL')
                        and CLASSSTRUCTURE.CLASSSTRUCTUREID = classancestor.ancestor)
          and classancestor.classstructureid = asset.classstructureid)
  AND asset.status IN ('IN STOCK', 'DEPLOYED')
  and (
    asset.manufacturer is null 
    or asset.ex_model is null 
    or asset.serialnum is null 
    or asset.assettag is null
    or asset.location in (select location from locations where classstructureid in ('1308', '1306', '1309'))
    or (assetcustodian.personid IS NULL and assetuser.personid IS NULL)
    or (assetuser.status != 'ACTIVE' or assetcustodian.status != 'ACTIVE'))
ORDER BY asset.assetnum;




select *
from classancestor
where exists (select *
              from classstructure 
              where exists 
                (select classstructureid 
                  from MAXIMO.classusewith 
                  where objectvalue = 'ASSET' 
                    and classusewith.classstructureid = classstructure.classstructureid)
                and classificationid in ('MOBILE', 'DESKTOP', 'MOBILEPHONE', 'MOBILEDATA', 'AUDIOVISUAL')
                and CLASSSTRUCTURE.CLASSSTRUCTUREID = classancestor.ancestor)
;


/*******************************************************************************
*  Assets without appropriate CIs
*******************************************************************************/

select ',='||asset.assetnum assetnum, asset.assetnum, asset.assettag,CLASSSTRUCTURE.CLASSIFICATIONID, asset.CHANGEBY, asset.CHANGEDATE
from asset
  left join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = asset.CLASSSTRUCTUREID
where CLASSSTRUCTURE.CLASSIFICATIONID in ('PHYSSERV', 'ROUTER', 'SWITCH', 'TAPESYS', 'PDU', 'PBX', 'NAS', 'SECDEV')
  and not exists (select 1 from ci where ci.assetnum = asset.assetnum)
order by CLASSSTRUCTURE.CLASSIFICATIONID, asset.CHANGEBY;


/*******************************************************************************
*  Active asset with decommissioned CI
*******************************************************************************/

select ',='||asset.assetnum assetnum, asset.assetnum, asset.assettag,CLASSSTRUCTURE.CLASSIFICATIONID, asset.CHANGEBY, asset.CHANGEDATE,
  cinum, ciname, CI.CHANGEBY CI_CHANGEBY, CI.CHANGEDATE CI_CHANGEDATE, ci.status CI_STATUS
from asset
  left join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = asset.CLASSSTRUCTUREID
  left join ci on CI.ASSETNUM = ASSET.ASSETNUM
where exists (select 1 from ci where ci.status != 'OPERATING' and ci.assetnum = asset.assetnum)
  and asset.status in ('IN STOCK', 'DEPLOYED')
order by CLASSSTRUCTURE.CLASSIFICATIONID, asset.CHANGEBY;


/*******************************************************************************
*  Assets with Manufacturer not in Manufacturer list
*******************************************************************************/

select assetnum, manufacturer
from asset
where manufacturer is not null
  and not exists
    (select 1
    from companies
    where companies.type = 'M'
      and companies.company = asset.manufacturer);


/*******************************************************************************
*  List of Makes/Models, by classification
*******************************************************************************/

select CLASSSTRUCTURE.CLASSIFICATIONID || '(' || CLASSSTRUCTURE.DESCRIPTION || ')' CLASSIFICATION, ASSET.MANUFACTURER, ASSET.EX_MODEL, count(*) ASSET_COUNT
from asset
  left join CLASSSTRUCTURE on CLASSSTRUCTURE.CLASSSTRUCTUREID = ASSET.CLASSSTRUCTUREID
where CLASSSTRUCTURE.CLASSIFICATIONID not in ('DESKTOP', 'CONFPHONE', 'PROJECTORSYS', 'FAX', 'VIRTDESKTOP', 'UPS', 'PRINTER', 'TABLET',
  'DESKPHONE', 'AUDIOVISUAL', 'LAPTOP', 'SMARTPHONE', 'MOBILEDATA', 'MOBILEPHONE')
  and asset.status not in ('DECOMMISSIONED', 'DISPOSED')
group by CLASSSTRUCTURE.CLASSIFICATIONID || '(' || CLASSSTRUCTURE.DESCRIPTION || ')', ASSET.MANUFACTURER, ASSET.EX_MODEL
order by CLASSSTRUCTURE.CLASSIFICATIONID || '(' || CLASSSTRUCTURE.DESCRIPTION || ')', ASSET.MANUFACTURER, ASSET.EX_MODEL;


select *
from CLASSSTRUCTURE
where CLASSSTRUCTURE.CLASSIFICATIONID in ('DESKTOP', 'TABLET','LAPTOP', 'SMARTPHONE', 'MOBILEDATA', 'MOBILEPHONE')
;


select ticketid, createdby
from ticket
where exists
  (select TICKETS.ticketid, TICKETS.CREATEDBY, PERSON.OWNERGROUP CREATEDBY_DEFAULT_GROUP, TICKETS.CREATIONDATE
  from ticket TICKETS
    left join person on person.personid = TICKETS.createdby
  where trunc(TICKETS.creationdate, 'MON') = add_months(trunc(sysdate, 'MON'), -1)
    and person.ownergroup = 'SERVICE DESK'
    and TICKETS.ticketid = :ticketid);
  