/*******************************************************************************
* Data Quality Checks to build
* - CIs that shouldn't have assets but do
* - 
* - 
* - 
* - 
*******************************************************************************/


/*******************************************************************************
*  CIs with no relationships
*******************************************************************************/

select ci.cinum, ci.ciname, CI.ASSETNUM, CI.PMCCIIMPACT, CI.EX_SUPPORTCALENDAR, CLASSSTRUCTURE.CLASSIFICATIONID, 
  ENVIRONMENT.ENVIRONMENT, ci.CCIPERSONGROUP OWNERGROUP, CI.CHANGEBY, person.ownergroup, CI.CHANGEDATE
from ci
  join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = CI.CLASSSTRUCTUREID
  join person on PERSON.PERSONID = CI.CHANGEBY
  left join (select cinum, assetattrid, alnvalue ENVIRONMENT from cispec where cispec.assetattrid = 'ENVIRONMENT') ENVIRONMENT on ENVIRONMENT.CINUM = ci.cinum
where 
  ci.status in 'OPERATING'
  and CLASSSTRUCTURE.CLASSIFICATIONID in ('CI.COMPUTERSYSTEMCLUSTER', 'CI.MSSQLSCHEMA', 
    'CI.ORACLESCHEMA', 'CI.SQLSERVERDATABASE', 'CI.SOFTWAREPRODUCT', 'CI.PHYSICALCOMPUTERSYSTEM', 
    'CI.VIRTUALCOMPUTERSYSTEM', 'CI.SOFTWAREINSTALLATION')
  and not exists 
    (select 1
    from CIRELATION
    where sourceci = ci.cinum or targetci = ci.cinum)
order by person.ownergroup, CLASSSTRUCTURE.CLASSIFICATIONID, ci.ciname;



/*******************************************************************************
*  CIs with no classification
*******************************************************************************/

select ', =' || ci.cinum, ci.cinum, ci.ciname, ci.status, ci.description, CI.CHANGEBY, PERSON.OWNERGROUP, CI.CHANGEDATE, A_CI.EAUDITTIMESTAMP, A_CI.EAUDITTYPE, A_CI.EAUDITUSERNAME, A_CI.CINAME PREV_NAME
from ci
  join person on CI.CHANGEBY = PERSON.PERSONID
  left join a_ci on (CI.CINUM = A_CI.CINUM)
where ci.CLASSSTRUCTUREID is null
  and ci.status not in ('DECOMMISSIONED')
order by ci.cinum;

/*******************************************************************************
*  CIs with no support calendar, business impact, support owner group
*******************************************************************************/

select ',='||ci.cinum CINUM, ci.cinum, ci.ciname, ci.description, CI.CHANGEBY, CI.CHANGEDATE,
  case when EX_SUPPORTCALENDAR is null then 'NO SUPPORT CALENDAR' else EX_SUPPORTCALENDAR end SUPPORTCAL, 
  case when PMCCIIMPACT is null then 'NO BUSINESS IMPACT' else to_char(PMCCIIMPACT) end BUSIMPACT, 
  case when CCIPERSONGROUP is null then 'NO OWNER GROUP' else CCIPERSONGROUP end OWNGROUP
from ci
where (EX_SUPPORTCALENDAR is null
  or PMCCIIMPACT is null
  or CCIPERSONGROUP is null)
  and classstructureid in ('1030', '1130', '1037', 'CCI00005', 'CCI00104')
  and status != 'DECOMMISSIONED';


/*******************************************************************************
*  CIs in a NOT READY status
*******************************************************************************/

select ',='||ci.cinum CINUM, ci.cinum, ci.ciname, ci.description, CLASSSTRUCTURE.CLASSIFICATIONID, 
  Cistatus.Changeby STATUS_CHGBY, PERSON.OWNERGROUP, Ci.Changedate STATUS_CHGDATE, 
  Multiassetlocci.Multiid, wochange.wonum, wochange.owner, wochange.ownergroup, WOCHANGE.DESCRIPTION, WOCHANGE.SCHEDSTART, WOCHANGE.SCHEDFINISH
from ci
  left join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = CI.CLASSSTRUCTUREID
  left join MULTIASSETLOCCI on MULTIASSETLOCCI.CINUM = CI.CINUM
  left join wochange on WOCHANGE.WONUM = MULTIASSETLOCCI.RECORDKEY
  left join cistatus on (Cistatus.Cinum = Ci.Cinum and cistatus.status = 'NOT READY')
  join person on person.personid = Cistatus.changeby
where ci.status = 'NOT READY'
  and Multiassetlocci.multiid in (select max(Multiassetlocci.multiid) from Multiassetlocci where recordclass = 'CHANGE' and Multiassetlocci.cinum = ci.cinum)
--  and CI.CHANGEDATE >= sysdate - 45
order by Cistatus.Changeby, Wochange.Schedstart;



/*******************************************************************************
*  Physical CIs without assets
*******************************************************************************/

select ',='||ci.cinum CINUM, ci.cinum, ci.ciname, /*ci.description,*/ CLASSSTRUCTURE.CLASSIFICATIONID, CCIPERSONGROUP OWNERGROUP, CI.CHANGEBY, CI.CHANGEDATE
from ci
  left join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = CI.CLASSSTRUCTUREID
where CLASSSTRUCTURE.CLASSIFICATIONID in ('CI.PHYSICALCOMPUTERSYSTEM', 'CI.ROUTER', 'CI.NETWORK', 'CI.FIREWALL', 'CI.PDU', 'CI.SWITCH', 'CI.GENERIC_COMPUTERSYSTEM', 'CI.WINDOWSCOMPUTERSYSTEM')
  and CI.ASSETNUM is null
order by CLASSSTRUCTURE.CLASSIFICATIONID, CI.CHANGEBY;


/*******************************************************************************
*  CIs with incomplete specs - Needs review
*******************************************************************************/

select 
--  ',=' || ci.cinum, ci.ciname, classstructure.classificationid, CISPEC.ASSETATTRID, CISPEC.ALNVALUE, ci.changeby, ci.changedate
  classstructure.classificationid, 
  CIspec.ASSETATTRID, 
  count(*) TOTAL,
  count(case when CIspec.alnvalue is not null then 'COMPLETE' else null end) COMPLETED_COUNT, 
  count(case when CIspec.alnvalue is null then 'NOTCOMPLETE' else null end) NOTCOMPLETED_COUNT, 
  round(count(case when CIspec.alnvalue is not null then 'COMPLETE' else null end) /count(*) * 100, 2) COMPLETED_PCT, 
  round(count(case when CIspec.alnvalue is null then 'NOTCOMPLETE' else null end) /count(*) * 100, 2) NOTCOMPLETED_PCT
from CI
  join classstructure on classstructure.classstructureid = ci.classstructureid
  join CIspec on CIspec.cinum = CI.cinum
where 1=1
  and ( 1=0
    OR (classstructure.classificationid = 'CI.COMPUTERSYSTEMCLUSTER' and CIspec.ASSETATTRID in ('ENVIRONMENT'))
    or (classstructure.classificationid = 'CI.MSSQLSCHEMA' and CIspec.ASSETATTRID in ('ENVIRONMENT', 'MANUFACTURER', 'VERSION'))
    or (classstructure.classificationid = 'CI.FIREWALL' and CIspec.ASSETATTRID in ('ENVIRONMENT'))
    or (classstructure.classificationid = 'CI.ORACLEDATABASE' and CIspec.ASSETATTRID in ('ENVIRONMENT', 'ORACLEDATABASE_DBVERSION'))
    or (classstructure.classificationid = 'CI.ORACLESCHEMA' and CIspec.ASSETATTRID in ('VERSION'))
    or (classstructure.classificationid = 'CI.PHYSICALCOMPUTERSYSTEM' and CIspec.ASSETATTRID in ('ENVIRONMENT', 'OPERATINGSYSTEM_NAME'/*, 'INTERNAL_IP_ADDRESS', 'RSA_IP_ADDRESS', 'STORAGE_IP_ADDRESS'*/))
    or (classstructure.classificationid = 'CI.RACK' and CIspec.ASSETATTRID in ('ENVIRONMENT'))
    or (classstructure.classificationid = 'CI.ROUTER' and CIspec.ASSETATTRID in ('ENVIRONMENT'))
    or (classstructure.classificationid = 'CI.SOFTWAREINSTALLATION' and CIspec.ASSETATTRID in ('ENVIRONMENT', 'APPLICATION_TYPE', 'MANUFACTURER', 'SUPPORTHOURS', 'VERSION'))
    or (classstructure.classificationid = 'CI.SOFTWAREPRODUCT' and CIspec.ASSETATTRID in ('ENVIRONMENT', 'MANUFACTURER', 'VERSION'))
    or (classstructure.classificationid = 'CI.SQLSERVERDATABASE' and CIspec.ASSETATTRID in ('ENVIRONMENT', 'MANUFACTURER', 'VERSION'))
    or (classstructure.classificationid = 'CI.VIRTUALCOMPUTERSYSTEM' and CIspec.ASSETATTRID in ('ENVIRONMENT', 'OPERATINGSYSTEM_NAME'/*, 'IPNETWORK_NAME', 'MAINTENANCE_WINDOW', 'INTERNAL_IP_ADDRESS', 'RSA_IP_ADDRESS', 'STORAGE_IP_ADDRESS'*/))
  )
  and classstructure.classificationid not in ('CI.BUSINESSSERVICE', 'CI.DNSSERVICE', 'CI.GENERIC_COMPUTERSYSTEM', 'CI.INFRASERVICE', 
                                              'CI.LDAPSERVICE', 'CI.NETWORKSERVICE', 'CI.SERVICE', 'CI.SYSTEMCONTROLLER', 'CI.TAPELIBRARY', 'CI.UPS', 'CI.WEBSERVICE')
--  and alnvalue is null
group by 
    classstructure.classificationid,
    CIspec.ASSETATTRID
order by 
  classstructure.classificationid,
--  ci.cinum, 
  CIspec.ASSETATTRID
;


/*******************************************************************************
*  Duplicate CI Names
*******************************************************************************/

select ',='||ci.cinum cinum, ci.ciname, classstructure.classificationid, 
  ci.changeby, ci.changedate, CICOUNT.cicount
from ci
  join classstructure on classstructure.classstructureid = ci.classstructureid
  left join
  (select ciname, count(*) CICOUNT
  from CI
    join classstructure on classstructure.classstructureid = ci.classstructureid
  where CI.STATUS != 'DECOMMISSIONED'
  group by ciname) CICOUNT on CI.CINAME = CICOUNT.CINAME
where CICOUNT.CICOUNT > 1
order by ci.ciname, ci.cinum;


/*******************************************************************************
*  Potentially invalid classifications
*******************************************************************************/

--Details
select ',='||ci.cinum CINUM, ci.cinum, ci.ciname, /*ci.description,*/ CLASSSTRUCTURE.CLASSIFICATIONID, 
  CCIPERSONGROUP OWNERGROUP, CI.CHANGEBY, CI.CHANGEDATE
from ci
  left join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = CI.CLASSSTRUCTUREID
where CLASSSTRUCTURE.CLASSIFICATIONID not in 
  ('CI.PHYSICALCOMPUTERSYSTEM', 'CI.ROUTER', 'CI.NETWORK', 'CI.FIREWALL', 'CI.PDU', 
  'CI.SWITCH', 'CI.SQLSERVERDATABASE', 'CI.WEBSERVICE', 'CI.NETWORKSERVICE', 'CI.MSSQLSCHEMA', 
  'CI.SOFTWARESERVICE', 'CI.DNSSERVICE', 'CI.STORAGEARRAY', 'CI.INFRASERVICE', 'CI.SOFTWAREPRODUCT', 
  'CI.BUSINESSSERVICE', 'CI.TELEPHONYINFRA', 'CI.RACK', 'CI.TELEPHONY', 'CI.TAPELIBRARY', 
  'CI.UPS', 'CI.ORACLESCHEMA', 'CI.COMPUTERSYSTEMCLUSTER', 'CI.LDAPSERVICE', 'CI.ORACLEDATABASE', 
  'CI.VIRTUALCOMPUTERSYSTEM', 'CI.SOFTWAREINSTALLATION', 'CI.SERVICE', 'CI.WINDOWSFILESYSTEM', 
  'CI.STORAGEVOLUME', 'CI.VMWAREDATASTORE');

--Count
select CLASSSTRUCTURE.CLASSIFICATIONID, count(*)
from ci
  left join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = CI.CLASSSTRUCTUREID
where CLASSSTRUCTURE.CLASSIFICATIONID not in 
  ('CI.PHYSICALCOMPUTERSYSTEM', 'CI.ROUTER', 'CI.NETWORK', 'CI.FIREWALL', 'CI.PDU', 
  'CI.SWITCH', 'CI.SQLSERVERDATABASE', 'CI.WEBSERVICE', 'CI.NETWORKSERVICE', 'CI.MSSQLSCHEMA', 
  'CI.SOFTWARESERVICE', 'CI.DNSSERVICE', 'CI.STORAGEARRAY', 'CI.INFRASERVICE', 'CI.SOFTWAREPRODUCT', 
  'CI.BUSINESSSERVICE', 'CI.TELEPHONYINFRA', 'CI.RACK', 'CI.TELEPHONY', 'CI.TAPELIBRARY', 
  'CI.UPS', 'CI.ORACLESCHEMA', 'CI.COMPUTERSYSTEMCLUSTER', 'CI.LDAPSERVICE', 'CI.ORACLEDATABASE', 
  'CI.VIRTUALCOMPUTERSYSTEM', 'CI.SOFTWAREINSTALLATION', 'CI.SERVICE', 'CI.WINDOWSFILESYSTEM', 
  'CI.STORAGEVOLUME', 'CI.VMWAREDATASTORE')
group by CLASSSTRUCTURE.CLASSIFICATIONID;


/*******************************************************************************
*  Active CI with decommissioned asset
*******************************************************************************/

select ',='||ci.cinum cinum, ci.cinum, ci.ciname, CLASSSTRUCTURE.CLASSIFICATIONID, ci.CHANGEBY, ci.CHANGEDATE
from ci
  left join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = ci.CLASSSTRUCTUREID
  join asset on CI.ASSETNUM = ASSET.ASSETNUM
where ci.status in ('NOT READY', 'OPERATING')
  and asset.status not in ('IN STOCK', 'DEPLOYED')
order by CLASSSTRUCTURE.CLASSIFICATIONID, CI.CHANGEBY;

/*******************************************************************************
*  Active asset with decommissioned CI
*******************************************************************************/

select ',='||asset.assetnum assetnum, asset.assetnum, asset.assettag, asset.status ASSETSTATUS, CLASSSTRUCTURE.CLASSIFICATIONID,
  ci.ciname, ci.status CISTATUS, ci.CHANGEBY, ci.CHANGEDATE
from asset
  left join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = asset.CLASSSTRUCTUREID
  join ci on ci.assetnum = asset.assetnum
where asset.status in ('IN STOCK', 'DEPLOYED')
  and ci.status not in ('OPERATING', 'NOT READY')
order by asset.assetnum;


/*******************************************************************************
*  Relationships to/from inactive CIs
*******************************************************************************/

select SOURCECI.STATUS src_status, SRC_CLASS.CLASSIFICATIONID src_class, SOURCECI.CINAME src_ciname,
  CIRELATION.RELATIONNUM, 
  TARGETCI.STATUS tgt_status, TGT_CLASS.CLASSIFICATIONID tgt_class, TARGETCI.CINAME tgt_ciname
from CIRELATION
  join ci sourceci on SOURCECI.CINUM = CIRELATION.SOURCECI
  left join CLASSSTRUCTURE src_class on src_class.CLASSSTRUCTUREID = SOURCECI.CLASSSTRUCTUREID
  join ci targetci on TARGETCI.CINUM = CIRELATION.TARGETCI
  left join classstructure tgt_class on TGT_CLASS.CLASSSTRUCTUREID = TARGETCI.CLASSSTRUCTUREID
where SOURCECI.STATUS = 'DECOMMISSIONED'
  or TARGETCI.STATUS = 'DECOMMISSIONED';


/*******************************************************************************
*  CIs with specs not based on classification
*******************************************************************************/

select 
--  distinct cispec.cinum
  cispec.cinum, ci.ciname, ci.changeby, ci.changedate, CLASSSTRUCTURE.DESCRIPTION, cispec.ASSETATTRID, CISPEC.ALNVALUE, CISPEC.NUMVALUE, CISPEC.CHANGEBY ATTRCHGBY, CISPEC.CHANGEDATE ATTRCHGDATE
--  CLASSSTRUCTURE.DESCRIPTION, cispec.ASSETATTRID, count(*)
from cispec
  left join CLASSSTRUCTURE on CLASSSTRUCTURE.CLASSSTRUCTUREID = CISPEC.CLASSSTRUCTUREID
  join ci on CISPEC.CINUM = CI.CINUM
where 1=1
--  and not exists (select 1 from classspec where CLASSSPEC.ASSETATTRID = CISPEC.ASSETATTRID and CLASSSPEC.CLASSSTRUCTUREID = CISPEC.CLASSSTRUCTUREID)
  and CLASSSTRUCTURE.DESCRIPTION in ('CI.MSSQLSCHEMA')
  and CISPEC.ASSETATTRID in ('MANUFACTURER')
--  and CISPEC.ALNVALUE != 'Microsoft'
--  and CISPEC.CHANGEBY not in ('MXINTADM')
--group by CLASSSTRUCTURE.DESCRIPTION, cispec.ASSETATTRID
--order by CLASSSTRUCTURE.DESCRIPTION, cispec.ASSETATTRID
;
