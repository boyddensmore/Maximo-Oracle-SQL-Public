/*******************************************************************************
*  FOR USE IN PROD
*  Details by Person - Priority on CUSTODIAN
*  
*******************************************************************************/

select person.personid, status, displayname, firstname, lastname, title,
  supervisor, location, addressline1, city, 
  company, EX_BUSINESSUNIT, department, deptdesc, cellnums.NUMBERS CELL_NUMBERS
from person
  left join (select personid, type, listagg(phonenum, '; ') within group (order by personid, type) NUMBERS
              from phone
              where type = 'CELL'
              group by personid, type) CELLNUMS on cellnums.personid = person.personid;


SELECT asset.assettag, 
--  asset.assetnum, asset.changedate, asset.changeby, asset.status, asset.serialnum, 
  asset.LOCATION, 
--  LOCATIONS.DESCRIPTION LOC_DESC, 
--  LOCCLASS.CLASSIFICATIONID LOCATION_CLASS, 
  classstructure.classificationid ASSET_CLASS, 
--  asset.manufacturer, asset.ex_model, 
  asset.ex_other, 
--  PHONENUMBER.PHONENUMBER,
--  MACADDR.MACADDRESS,
  assetuser.personid usr, 
--  assetuser.phonenum USER_PHONE, ASSETUSER.SUPERVISOR usr_super, 
  assetcustodian.personid custodian, 
--  assetcustodian.phonenum CUSTODIAN_PHONE, ASSETCUSTODIAN.SUPERVISOR cust_super,
--  CASE WHEN assetcustodian.personid IS NULL THEN CASE WHEN assetuser.personid IS NULL THEN 'NO USER OR CUST' ELSE 'USER' END ELSE 'CUSTODIAN' END usercust_record_used,
--  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.personid ELSE assetcustodian.personid END selected_person,
--  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.status ELSE assetcustodian.status END selected_person_status,
--  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.isprimary ELSE assetcustodian.isprimary END selected_isprimary,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.company ELSE assetcustodian.company END selected_company,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.ex_businessunit ELSE assetcustodian.ex_businessunit END selected_businessunit,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.department ELSE assetcustodian.department END selected_department,
--  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.deptdesc ELSE assetcustodian.deptdesc END selected_deptdesc,
  assetuser.department USER_DEPT, assetcustodian.department CUST_DEPT
FROM asset
  JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  join locations on LOCATIONS.LOCATION = ASSET.LOCATION
  left join CLASSSTRUCTURE LOCCLASS on LOCATIONS.CLASSSTRUCTUREID = LOCCLASS.CLASSSTRUCTUREID
  left join (select assetnum, assetattrid, alnvalue PHONENUMBER from assetspec where assetspec.assetattrid = 'PHONENUMBER') PHONENUMBER on PHONENUMBER.assetnum = asset.assetnum
--  left join (select assetnum, assetattrid, alnvalue MACADDRESS from assetspec where assetspec.assetattrid in ('COMPUTERSYSTEM_PRIMARYMACADDRESS', 'MAC')) MACADDR on MACADDR.assetnum = asset.assetnum
  LEFT JOIN
  (SELECT asset.assetnum, person.personid, phone.phonenum, person.company, person.ex_businessunit, person.department, person.deptdesc, PERSON.SUPERVISOR, person.status, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
    left join phone on (phone.personid = person.personid and phone.isprimary = 1)
    JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  WHERE (classstructure.classificationid IN ('DESKTOP', 'LAPTOP', 'VIRTDESKTOP'/*, 'TABLET', 'MOBILEPHONE', 'SMARTPHONE', 'DESKPHONE', 'CONFPHONE'*/)
    OR upper(asset.ex_model) LIKE '%SURFACE%')
    AND assetusercust.iscustodian = 1
  ORDER BY asset.assetnum) assetcustodian ON assetcustodian.assetnum = asset.assetnum
  LEFT JOIN
  (SELECT asset.assetnum,person.personid, phone.phonenum, person.company, person.ex_businessunit, person.department, person.deptdesc, PERSON.SUPERVISOR, person.status, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
    left join phone on (phone.personid = person.personid and phone.isprimary = 1)
    JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  WHERE (classstructure.classificationid IN ('DESKTOP', 'LAPTOP', 'VIRTDESKTOP'/*, 'TABLET', 'MOBILEPHONE', 'SMARTPHONE', 'DESKPHONE', 'CONFPHONE'*/)
    OR upper(asset.ex_model) LIKE '%SURFACE%')
    AND assetusercust.isuser = 1
  ORDER BY asset.assetnum) assetuser ON assetuser.assetnum = asset.assetnum
WHERE (classstructure.classificationid IN ('DESKTOP', 'LAPTOP', 'VIRTDESKTOP'/*, 'TABLET', 'MOBILEPHONE', 'SMARTPHONE', 'DESKPHONE', 'CONFPHONE'*/)
    OR upper(asset.ex_model) LIKE '%SURFACE%')
  AND asset.status IN ('DEPLOYED')
-- + whereText
--and asset.assetnum = '5387'
ORDER BY asset.assetnum;

select classstructure.DESCRIPTION, count(*) ASSET_COUNT
from assetspec 
  left join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = ASSETSPEC.CLASSSTRUCTUREID
where assetspec.assetattrid in ('MAC')
group by classstructure.DESCRIPTION
order by count(*) desc;


/*******************************************************************************
*  FOR USE IN PROD - IPADS
*  Details by Person - Priority on CUSTODIAN
*  
*******************************************************************************/

SELECT asset.assetuid, asset.assetnum, asset.assettag, asset.status, asset.serialnum, asset.LOCATION, LOCATIONS.DESCRIPTION LOC_DESC, 
  LOCCLASS.CLASSIFICATIONID LOCATION_CLASS, classstructure.classificationid ASSET_CLASS, asset.manufacturer, asset.ex_model, 
  asset.ex_other, assetuser.personid usr, assetcustodian.personid custodian,
  CASE WHEN assetcustodian.personid IS NULL THEN CASE WHEN assetuser.personid IS NULL THEN 'NO USER OR CUST' ELSE 'USER' END ELSE 'CUSTODIAN' END usercust_record_used,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.personid ELSE assetcustodian.personid END selected_person,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.status ELSE assetcustodian.status END selected_person_status,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.isprimary ELSE assetcustodian.isprimary END selected_isprimary,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.company ELSE assetcustodian.company END selected_company,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.ex_businessunit ELSE assetcustodian.ex_businessunit END selected_businessunit,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.department ELSE assetcustodian.department END selected_department,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.deptdesc ELSE assetcustodian.deptdesc END selected_deptdesc
FROM asset
  JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  join locations on LOCATIONS.LOCATION = ASSET.LOCATION
  left join CLASSSTRUCTURE LOCCLASS on LOCATIONS.CLASSSTRUCTUREID = LOCCLASS.CLASSSTRUCTUREID
  LEFT JOIN
  (SELECT asset.assetnum, person.personid, person.company, person.ex_businessunit, person.department, person.deptdesc, person.status, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
    JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  WHERE classstructure.classificationid IN ('TABLET')
    and ASSET.MANUFACTURER = 'APPLE'
    AND assetusercust.iscustodian = 1
  ORDER BY asset.assetnum) assetcustodian ON assetcustodian.assetnum = asset.assetnum
  LEFT JOIN
  (SELECT asset.assetnum,person.personid, person.company, person.ex_businessunit, person.department, person.deptdesc, person.status, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
    JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  WHERE classstructure.classificationid IN ('TABLET')
    and ASSET.MANUFACTURER = 'APPLE'
    AND assetusercust.isuser = 1
  ORDER BY asset.assetnum) assetuser ON assetuser.assetnum = asset.assetnum
WHERE classstructure.classificationid IN ('TABLET')
  and ASSET.MANUFACTURER = 'APPLE'
  AND asset.status IN ('DEPLOYED')
-- + whereText
ORDER BY asset.assetnum;


/*******************************************************************************
*  Comparing selection of custodians vs users
*******************************************************************************/

SELECT 
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.company ELSE assetcustodian.company END CUSTODIAN_company,
  CASE WHEN assetuser.personid IS NULL THEN assetcustodian.company ELSE assetuser.company END USER_company,
  CASE WHEN assetuser.personid IS NULL THEN assetcustodian.department ELSE assetuser.department END selected_department,
  count(*)
FROM asset
  JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  LEFT JOIN
  (SELECT asset.assetnum, person.personid, person.company, person.ex_businessunit, person.department, person.deptdesc, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
  WHERE (asset.classstructureid IN ('1238', '1243')
    OR upper(asset.ex_model) LIKE '%SURFACE%')
    AND assetusercust.iscustodian = 1
  ORDER BY asset.assetnum) assetcustodian ON assetcustodian.assetnum = asset.assetnum
  LEFT JOIN
  (SELECT asset.assetnum,person.personid, person.company, person.ex_businessunit, person.department, person.deptdesc, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
  WHERE (asset.classstructureid IN ('1238', '1243')
    OR upper(asset.ex_model) LIKE '%SURFACE%')
    AND assetusercust.isuser = 1
  ORDER BY asset.assetnum) assetuser ON assetuser.assetnum = asset.assetnum
WHERE (asset.classstructureid IN ('1238', '1243')
    OR upper(asset.ex_model) LIKE '%SURFACE%')
  AND asset.status IN ('DEPLOYED', 'IN STOCK')
group by CASE WHEN assetcustodian.personid IS NULL THEN assetuser.company ELSE assetcustodian.company END,
  CASE WHEN assetuser.personid IS NULL THEN assetcustodian.company ELSE assetuser.company END,
  CASE WHEN assetuser.personid IS NULL THEN assetcustodian.department ELSE assetuser.department END;



/*******************************************************************************
*  Count grouped by Department
*******************************************************************************/

SELECT person.company, person.EX_BUSINESSUNIT, person.department, person.deptdesc, count(asset.assetnum)
FROM asset
  LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
  LEFT JOIN person ON person.personid = assetusercust.personid
WHERE (asset.classstructureid IN ('1238', '1243')
    OR upper(asset.ex_model) LIKE '%SURFACE%')
  AND asset.status IN ('DEPLOYED', 'IN STOCK')
GROUP BY person.company, person.EX_BUSINESSUNIT, person.department, person.deptdesc
ORDER BY count(asset.assetnum) DESC;


/*******************************************************************************
*  Count grouped by Company
*******************************************************************************/

SELECT person.company, count(asset.assetnum)
FROM asset
  LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
  JOIN person ON person.personid = assetusercust.personid
WHERE (asset.classstructureid IN ('1238', '1243')
    OR upper(asset.ex_model) LIKE '%SURFACE%')
  AND asset.status IN ('DEPLOYED')
  AND asset.assetnum IN ('1160', '1161', '1162', '1163')
GROUP BY person.company
ORDER BY person.company;


/*******************************************************************************
*  All assets, for validation
*  
*******************************************************************************/

SELECT asset.assetuid, asset.assetnum, asset.assettag, asset.status, asset.serialnum, asset.LOCATION, LOCATIONS.DESCRIPTION LOC_DESC, 
  LOCCLASS.CLASSIFICATIONID LOCATION_CLASS, classstructure.classificationid ASSET_CLASS, asset.manufacturer, asset.ex_model, 
  asset.ex_other, assetuser.personid usr, ASSETUSER.SUPERVISOR usr_super, assetcustodian.personid custodian, ASSETCUSTODIAN.SUPERVISOR cust_super,
  CASE WHEN assetcustodian.personid IS NULL THEN CASE WHEN assetuser.personid IS NULL THEN 'NO USER OR CUST' ELSE 'USER' END ELSE 'CUSTODIAN' END usercust_record_used,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.personid ELSE assetcustodian.personid END selected_person,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.status ELSE assetcustodian.status END selected_person_status,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.isprimary ELSE assetcustodian.isprimary END selected_isprimary,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.company ELSE assetcustodian.company END selected_company,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.ex_businessunit ELSE assetcustodian.ex_businessunit END selected_businessunit,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.department ELSE assetcustodian.department END selected_department,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.deptdesc ELSE assetcustodian.deptdesc END selected_deptdesc
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
ORDER BY asset.assetnum;


/*******************************************************************************
*  Rollups
*  
*******************************************************************************/

SELECT 
  grouping(CASE WHEN assetcustodian.personid IS NULL THEN assetuser.company ELSE assetcustodian.company END) company_GRP,
  grouping(CASE WHEN assetcustodian.personid IS NULL THEN assetuser.ex_businessunit ELSE assetcustodian.ex_businessunit END) businessunit_GRP,
  grouping(CASE WHEN assetcustodian.personid IS NULL THEN assetuser.department ELSE assetcustodian.department END) department_GRP,
  grouping(CASE WHEN assetcustodian.personid IS NULL THEN assetuser.deptdesc ELSE assetcustodian.deptdesc END) deptdesc_GRP,
  grouping(classstructure.classificationid) CLASS_GRP,
  grouping(asset.manufacturer) manuf_GRP, 
  grouping(asset.ex_model) MODEL_GRP,
  
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.company ELSE assetcustodian.company END selected_company,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.ex_businessunit ELSE assetcustodian.ex_businessunit END selected_businessunit,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.department ELSE assetcustodian.department END selected_department,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.deptdesc ELSE assetcustodian.deptdesc END selected_deptdesc,
  classstructure.classificationid ASSET_CLASS, asset.manufacturer, asset.ex_model,
  count(*)
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
  WHERE (classstructure.classificationid IN ('DESKTOP', 'LAPTOP', 'VIRTDESKTOP')
    OR upper(asset.ex_model) LIKE '%SURFACE%')
    AND assetusercust.iscustodian = 1
  ORDER BY asset.assetnum) assetcustodian ON assetcustodian.assetnum = asset.assetnum
  LEFT JOIN
  (SELECT asset.assetnum,person.personid, person.company, person.ex_businessunit, person.department, person.deptdesc, PERSON.SUPERVISOR, person.status, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
  FROM asset
    LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
    LEFT JOIN person ON person.personid = assetusercust.personid
    JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
  WHERE (classstructure.classificationid IN ('DESKTOP', 'LAPTOP', 'VIRTDESKTOP')
    OR upper(asset.ex_model) LIKE '%SURFACE%')
    AND assetusercust.isuser = 1
  ORDER BY asset.assetnum) assetuser ON assetuser.assetnum = asset.assetnum
WHERE (classstructure.classificationid IN ('DESKTOP', 'LAPTOP', 'VIRTDESKTOP')
    OR upper(asset.ex_model) LIKE '%SURFACE%')
  AND asset.status IN ('DEPLOYED')
-- + whereText
group by rollup
  (CASE WHEN assetcustodian.personid IS NULL THEN assetuser.company ELSE assetcustodian.company END,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.ex_businessunit ELSE assetcustodian.ex_businessunit END,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.department ELSE assetcustodian.department END,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.deptdesc ELSE assetcustodian.deptdesc END,
  classstructure.classificationid, asset.manufacturer, asset.ex_model)
order by
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.company ELSE assetcustodian.company END,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.ex_businessunit ELSE assetcustodian.ex_businessunit END,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.department ELSE assetcustodian.department END,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.deptdesc ELSE assetcustodian.deptdesc END,
  classstructure.classificationid, asset.manufacturer, asset.ex_model;