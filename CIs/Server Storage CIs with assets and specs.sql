
/*******************************************************************************
*  FINAL
*******************************************************************************/

select CI.CINUM, CI.CINAME, CI.STATUS, CI.DESCRIPTION, CLASSSTRUCTURE.CLASSIFICATIONID, 
  ASSET.MANUFACTURER, ASSET.EX_MODEL, ASSET.SERIALNUM, ASSET.LOCATION,
  CI.EX_AUTHCIAPPSUPPCONTACT APP_SUPP_CONTACT, CI.EX_AUTHCIBUOWNER CI_BUS_OWNER, 
  CI.EX_AUTHCINETWORK NETWORK, CI.EX_AUTHCISYSTEMCONTACT SYSTEM_CONTACT, 
  ENVIRONMENT.ENVIRONMENT, ASSET.TLOAMREFRESHPLANDATE WARRANTY_EXPIRY,
  INTERNAL_IP_ADDRESS.INTERNAL_IP_ADDRESS, MAINTENANCE_WINDOW.MAINTENANCE_WINDOW, 
  OPERATINGSYSTEM_NAME.OPERATINGSYSTEM_NAME, FIRMWARE.FIRMWARE,
  RSA_IP_ADDRESS.RSA_IP_ADDRESS, 
  STORAGE_IP_ADDRESS.STORAGE_IP_ADDRESS
  ,Relatedci.Source_Ciname RELATEDCI
  ,Relatedci.Relationnum RELATION
from ci
  left join (select cinum, assetattrid, alnvalue ENVIRONMENT from cispec where cispec.assetattrid = 'ENVIRONMENT') ENVIRONMENT on ENVIRONMENT.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue INTERNAL_IP_ADDRESS from cispec where cispec.assetattrid = 'INTERNAL_IP_ADDRESS') INTERNAL_IP_ADDRESS on INTERNAL_IP_ADDRESS.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue MAINTENANCE_WINDOW from cispec where cispec.assetattrid = 'MAINTENANCE_WINDOW') MAINTENANCE_WINDOW on MAINTENANCE_WINDOW.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue OPERATINGSYSTEM_NAME from cispec where cispec.assetattrid = 'OPERATINGSYSTEM_NAME') OPERATINGSYSTEM_NAME on OPERATINGSYSTEM_NAME.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue FIRMWARE from cispec where cispec.assetattrid = 'FIRMWARE') FIRMWARE on FIRMWARE.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue RSA_IP_ADDRESS from cispec where cispec.assetattrid = 'RSA_IP_ADDRESS') RSA_IP_ADDRESS on RSA_IP_ADDRESS.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue STORAGE_IP_ADDRESS from cispec where cispec.assetattrid = 'STORAGE_IP_ADDRESS') STORAGE_IP_ADDRESS on STORAGE_IP_ADDRESS.CINUM = ci.cinum
  left join Asset on CI.ASSETNUM = ASSET.ASSETNUM
  join Classstructure on CI.CLASSSTRUCTUREID = Classstructure.CLASSSTRUCTUREID
  left join (select ci.cinum TARGET_CINUM, Ci.Ciname TARGET_CINAME, Cirelation.Relationnum, Sourceci.Ciname SOURCE_CINAME
    from ci
      join cirelation on Cirelation.Targetci = Ci.Cinum
      join ci sourceci on Cirelation.Sourceci = Sourceci.Cinum
    where Sourceci.Classstructureid not in ('1185', 'CCI00112')) RELATEDCI on Ci.Cinum = Relatedci.target_Cinum
where 1=1
  and CI.CLASSSTRUCTUREID in 
    (select CLASSSTRUCTURE.CLASSSTRUCTUREID
      from classstructure
      where CLASSSTRUCTURE.description in 
        ('CI.PHYSICALCOMPUTERSYSTEM', 'CI.STORAGEARRAY', 'CI.TAPELIBRARY', 'CI.RACK', 
        'CI.COMPUTERSYSTEMCLUSTER', 'CI.UPS', 'CI.VIRTUALCOMPUTERSYSTEM', 'CI.SWITCH',
        'CI.FIREWALL', 'CI.ROUTER', 'CI.PDU', 'CI.NETWORKSERVICE', 'CI.NETWORK'))
  and ci.STATUS not in ('DECOMMISSIONED')
  order by ci.cinum;


select Ci.Cinum, Ci.Ciname, /*Ci.Description CI_DESCRIPTION, Ci.Classstructureid CI_CLASSSTRUCTUREID, Ci.Status CI_STATUS, 
  Ci.Ex_Authciappsuppcontact, Ci.Ex_Authcibuowner, Ci.Ex_Authcinetwork, Ci.Ex_Authcisystemcontact,*/
  Cispec.Assetattrid CI_SPEC, Cispec.Alnvalue CI_SPEC_VALUE,
  Asset.Assetnum, Asset.Assettag, Asset.Description ASSET_DESCRIPTION, Asset.Serialnum, Asset.Location,
  Asset.Manufacturer, Asset.Ex_Model, Asset.Status ASSET_STATUS, Asset.Tloamrefreshplandate REFRESH_PLAN_DATE,
  Assetspec.Assetattrid ASSET_SPEC, Assetspec.Alnvalue ASSET_SPEC_VALUE
from ci
  join Cispec on Cispec.Cinum = Ci.Cinum
  right join Asset on Asset.Assetnum = Ci.Assetnum
  join Assetspec on Assetspec.Assetnum = Asset.Assetnum
where CI.CLASSSTRUCTUREID in ('1070', '1122', '1124', '1184', '1185', '1239', 'CCI00112')
/*and Cispec.Assetattrid not in ('INTERNAL_IP_ADDRESS', 'OPERATINGSYSTEM_NAME', 
    'ENVIRONMENT', 'MODEL', 'MANUFACTURER', 'COMPUTERSYSTEM_FQDN', 'COMPUTERSYSTEM_SERIALNUMBER', 
    'VERSION', 'ENVIRONMENT_NUMBER', 'SUSTAINMENT_OR_PROJECT_LANDSCAPE', 'FUNCTION') */ ;

select count(*)
from ci
where CI.CLASSSTRUCTUREID in ('1070', '1122', '1124', '1184', '1185', '1239', 'CCI00112');