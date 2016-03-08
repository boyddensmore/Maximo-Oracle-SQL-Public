/*******************************************************************************
*  Run this first if you get an error saying the table or view can't be found.
*******************************************************************************/

ALTER SESSION SET CURRENT_SCHEMA = Maximo;


/*******************************************************************************
*  List of all assets maintained by Deskside
*******************************************************************************/

SELECT asset.assettag, asset.status, asset.serialnum, asset.LOCATION, LOCATIONS.DESCRIPTION LOC_DESC, 
  LOCCLASS.CLASSIFICATIONID LOCATION_CLASS, classstructure.classificationid ASSET_CLASS, asset.manufacturer, asset.ex_model, 
  asset.ex_other, assetuser.personid usr, ASSETUSER.SUPERVISOR usr_super, assetcustodian.personid custodian, ASSETCUSTODIAN.SUPERVISOR cust_super,
  CASE WHEN assetcustodian.personid IS NULL THEN CASE WHEN assetuser.personid IS NULL THEN 'NO USER OR CUST' ELSE 'USER' END ELSE 'CUSTODIAN' END usercust_record_used,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.personid ELSE assetcustodian.personid END selected_person,
  CASE WHEN assetcustodian.personid IS NULL THEN assetuser.status ELSE assetcustodian.status END selected_person_status,
  case when asset.manufacturer is null then 'INCOMPLETE' else 'COMPLETE' end MANUFACTURER_INCOMPLETE,
  case when asset.ex_model is null then 'INCOMPLETE' else 'COMPLETE' end MODEL_INCOMPLETE,
  case when asset.serialnum is null then 'INCOMPLETE' else 'COMPLETE' end SERIAL_INCOMPLETE,
  case when asset.location in (select location from locations where classstructureid in ('1308', '1306', '1309')) then 'INCOMPLETE' else 'COMPLETE' end LOCATION_INCOMPLETE
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
    WHERE assetusercust.iscustodian = 1) assetcustodian ON assetcustodian.assetnum = asset.assetnum
  LEFT JOIN
    (SELECT asset.assetnum,person.personid, person.company, person.ex_businessunit, person.department, person.deptdesc, PERSON.SUPERVISOR, person.status, assetusercust.isuser, assetusercust.isprimary, assetusercust.iscustodian
    FROM asset
      LEFT JOIN assetusercust ON assetusercust.assetnum = asset.assetnum
      LEFT JOIN person ON person.personid = assetusercust.personid
      JOIN classstructure ON asset.classstructureid = classstructure.classstructureid
    WHERE assetusercust.isuser = 1) assetuser ON assetuser.assetnum = asset.assetnum
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
  AND asset.status NOT IN ('DISPOSED', 'DECOMMISSIONED', 'MISSING');