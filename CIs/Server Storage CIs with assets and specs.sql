
/*******************************************************************************
*  FINAL
*******************************************************************************/

select CI.CINUM, CI.CINAME, ci.changedate CI_changedate, ci.changeby CI_changeby, CI.STATUS, CI.DESCRIPTION, CLASSSTRUCTURE.CLASSIFICATIONID, 
  CI.PMCCIIMPACT BUSINESS_IMPACT,
  CI.EX_SUPPORTCALENDAR SUPPORT_CALENDAR,
  asset.assetnum,
  asset.changedate asset_changedate, asset.changeby asset_changeby, ASSET.MANUFACTURER, ASSET.EX_MODEL, 
  ASSET.SERIALNUM,
  ASSET.LOCATION,
  ci.CCIPERSONGROUP SUPPORT_OWNER_GROUP,
  CI.EX_AUTHCIAPPSUPPCONTACT APP_SUPP_CONTACT, CI.EX_AUTHCIBUOWNER CI_BUS_OWNER, 
/*  CI.EX_AUTHCINETWORK NETWORK, */
  CI.EX_AUTHCISYSTEMCONTACT SYSTEM_CONTACT, 
  ENVIRONMENT.ENVIRONMENT, ASSET.TLOAMREFRESHPLANDATE WARRANTY_EXPIRY,
/*  INTERNAL_IP_ADDRESS.INTERNAL_IP_ADDRESS, */
/*  MAINTENANCE_WINDOW.MAINTENANCE_WINDOW, */
  OPERATINGSYSTEM_NAME.OPERATINGSYSTEM_NAME, 
  VERSION.VERSION,
  FIRMWARE.FIRMWARE,
  HOSTING_SUBSCRIPTION.HOSTING_SUBSCRIPTION,
/*  RSA_IP_ADDRESS.RSA_IP_ADDRESS, */
/*  STORAGE_IP_ADDRESS.STORAGE_IP_ADDRESS, */
  RUNSONCLUSTER.CINAME RUNS_ON_CLUSTER,
  RUNSONSERVERS.SERVERS RUNS_ON_SERVERS,
  USESDATABASES.DATABASES USES_DATABASES,
  ALLRELS.CIRELATIONS
from ci
  left join (select cinum, assetattrid, alnvalue ENVIRONMENT from cispec where cispec.assetattrid = 'ENVIRONMENT') ENVIRONMENT on ENVIRONMENT.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue HOSTING_SUBSCRIPTION from cispec where cispec.assetattrid = 'HOSTING_SUBSCRIPTION') HOSTING_SUBSCRIPTION on HOSTING_SUBSCRIPTION.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue INTERNAL_IP_ADDRESS from cispec where cispec.assetattrid = 'INTERNAL_IP_ADDRESS') INTERNAL_IP_ADDRESS on INTERNAL_IP_ADDRESS.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue MAINTENANCE_WINDOW from cispec where cispec.assetattrid = 'MAINTENANCE_WINDOW') MAINTENANCE_WINDOW on MAINTENANCE_WINDOW.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue OPERATINGSYSTEM_NAME from cispec where cispec.assetattrid = 'OPERATINGSYSTEM_NAME') OPERATINGSYSTEM_NAME on OPERATINGSYSTEM_NAME.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue VERSION from cispec where cispec.assetattrid = 'VERSION') VERSION on VERSION.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue FIRMWARE from cispec where cispec.assetattrid = 'FIRMWARE') FIRMWARE on FIRMWARE.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue RSA_IP_ADDRESS from cispec where cispec.assetattrid = 'RSA_IP_ADDRESS') RSA_IP_ADDRESS on RSA_IP_ADDRESS.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue STORAGE_IP_ADDRESS from cispec where cispec.assetattrid = 'STORAGE_IP_ADDRESS') STORAGE_IP_ADDRESS on STORAGE_IP_ADDRESS.CINUM = ci.cinum
  left join Asset on CI.ASSETNUM = ASSET.ASSETNUM
  join Classstructure on CI.CLASSSTRUCTUREID = Classstructure.CLASSSTRUCTUREID
  /* Runs On Cluster */
  left join (select cirelation.sourceci, CIRELATION.RELATIONNUM, TARGETCI.CINUM, TARGETCI.CINAME
              from cirelation
                join ci targetci on targetci.cinum = cirelation.targetci
              where TARGETCI.CLASSSTRUCTUREID in (select classstructureid from classstructure 
                                                  where description in ('CI.COMPUTERSYSTEMCLUSTER'))
            ) RUNSONCLUSTER on ci.cinum = RUNSONCLUSTER.sourceci
  /* Runs On Servers */
  left join (select cirelation.sourceci,
                    listagg(TARGETCI.CINAME, ', ') WITHIN GROUP (ORDER BY cirelation.sourceci) SERVERS
              from cirelation
                join ci targetci on targetci.cinum = cirelation.targetci
              where TARGETCI.CLASSSTRUCTUREID in (select classstructureid from classstructure 
                                                  where description in ('CI.PHYSICALCOMPUTERSYSTEM', 'CI.VIRTUALCOMPUTERSYSTEM', 'CI.COMPUTERSYSTEM'))
                and CIRELATION.RELATIONNUM = 'RELATION.RUNSON'
              group by cirelation.sourceci) RUNSONSERVERS on ci.cinum = RUNSONSERVERS.sourceci
  /* Uses Databases */
  left join (select cirelation.targetci,
                    listagg(sourceci.CINAME, ', ') WITHIN GROUP (ORDER BY cirelation.targetci) DATABASES
              from cirelation
                join ci sourceci on sourceci.cinum = cirelation.sourceci
              where sourceci.CLASSSTRUCTUREID in (select classstructureid from classstructure 
                                                  where description in ('CI.ORACLEDATABASE', 'CI.SQLSERVERDATABASE', 
                                                                        'CI.MSSQLSCHEMA', 'CI.ORACLEINSTANCE', 'CI.ORACLESCHEMA'))
                and CIRELATION.RELATIONNUM = 'RELATION.SUPPORTS'
              group by cirelation.targetci) USESDATABASES on ci.cinum = USESDATABASES.targetci
  /* Supports Applications */
  left join (select cirelation.sourceci,
                    listagg(targetci.CINAME, ', ') WITHIN GROUP (ORDER BY cirelation.sourceci) DATABASES
              from cirelation
                join ci targetci on targetci.cinum = cirelation.targetci
              where targetci.CLASSSTRUCTUREID in (select classstructureid from classstructure 
                                                  where description in ('CI.SOFTWARESERVICE', 'CI.SOFTWAREINSTALLATION', 'CI.SOFTWAREPRODUCT'))
                and CIRELATION.RELATIONNUM = 'RELATION.SUPPORTS'
              group by cirelation.sourceci) USESDATABASES on ci.cinum = USESDATABASES.sourceci
  /* All Relationships */
  left join (select 
              case when relationnum in ('RELATION.SUPPORTS') then targetci else sourceci end SOURCECI,
              listagg(replace(decode(relationnum, 'RELATION.SUPPORTS', 'RELATION.SUPPORTED_BY', relationnum), 'RELATION.', '') || ' ' || targetci.ciname, ', ') 
                WITHIN GROUP (ORDER BY targetci.ciname) CIRELATIONS
            from cirelation
              join ci SOURCECI on sourceci.cinum = case when relationnum in ('RELATION.SUPPORTS') then targetci else sourceci end
              join ci TARGETCI on targetci.cinum = case when relationnum in ('RELATION.SUPPORTS') then sourceci else targetci end
            group by case when relationnum in ('RELATION.SUPPORTS') then targetci else sourceci end
            ) ALLRELS on ALLRELS.sourceci = ci.cinum
where 1=1
  and ci.STATUS not in ('DECOMMISSIONED')
  order by ci.cinum
;



/*******************************************************************************
*  Details for CIs with open changes for CI review
*******************************************************************************/


select CHANGES_FOR_REVIEW.ownergroup CHG_OWNERGROUP, CHANGES_FOR_REVIEW.owner CHG_OWNER,
  ', =' || CHANGES_FOR_REVIEW.wonum WONUM1, CHANGES_FOR_REVIEW.wonum WONUM2, 
  decode(CHANGES_FOR_REVIEW.nodeid, 136, 'Coord Review', 137, 'Returned') STATE,
  CHANGES_FOR_REVIEW.description,
  CHANGES_FOR_REVIEW.schedstart, CHANGES_FOR_REVIEW.schedfinish,
  ', =' || CI.CINUM CINUM1, 
  CI.CINUM CINUM2, 
  CI.CINAME, ci.changedate CI_changedate, ci.changeby CI_changeby, CI.STATUS, CI.DESCRIPTION, CLASSSTRUCTURE.CLASSIFICATIONID, 
  CI.PMCCIIMPACT BUSINESS_IMPACT,
  CI.EX_SUPPORTCALENDAR SUPPORT_CALENDAR,
  asset.assetnum,
  asset.changedate asset_changedate, asset.changeby asset_changeby, ASSET.MANUFACTURER, ASSET.EX_MODEL, 
  ASSET.SERIALNUM,
  ASSET.LOCATION,
  ci.CCIPERSONGROUP SUPPORT_OWNER_GROUP,
  CI.EX_AUTHCIAPPSUPPCONTACT APP_SUPP_CONTACT, CI.EX_AUTHCIBUOWNER CI_BUS_OWNER, 
  CI.EX_AUTHCISYSTEMCONTACT SYSTEM_CONTACT, 
  ENVIRONMENT.ENVIRONMENT, ASSET.TLOAMREFRESHPLANDATE WARRANTY_EXPIRY,
  OPERATINGSYSTEM_NAME.OPERATINGSYSTEM_NAME, 
  VERSION.VERSION,
  FIRMWARE.FIRMWARE,
  HOSTING_SUBSCRIPTION.HOSTING_SUBSCRIPTION,
  RUNSONCLUSTER.CINAME RUNS_ON_CLUSTER,
  RUNSONSERVERS.SERVERS RUNS_ON_SERVERS,
  USESDATABASES.DATABASES USES_DATABASES,
  ALLRELS.CIRELATIONS
from ci
  left join (select cinum, assetattrid, alnvalue ENVIRONMENT from cispec where cispec.assetattrid = 'ENVIRONMENT') ENVIRONMENT on ENVIRONMENT.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue HOSTING_SUBSCRIPTION from cispec where cispec.assetattrid = 'HOSTING_SUBSCRIPTION') HOSTING_SUBSCRIPTION on HOSTING_SUBSCRIPTION.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue INTERNAL_IP_ADDRESS from cispec where cispec.assetattrid = 'INTERNAL_IP_ADDRESS') INTERNAL_IP_ADDRESS on INTERNAL_IP_ADDRESS.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue MAINTENANCE_WINDOW from cispec where cispec.assetattrid = 'MAINTENANCE_WINDOW') MAINTENANCE_WINDOW on MAINTENANCE_WINDOW.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue OPERATINGSYSTEM_NAME from cispec where cispec.assetattrid = 'OPERATINGSYSTEM_NAME') OPERATINGSYSTEM_NAME on OPERATINGSYSTEM_NAME.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue VERSION from cispec where cispec.assetattrid = 'VERSION') VERSION on VERSION.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue FIRMWARE from cispec where cispec.assetattrid = 'FIRMWARE') FIRMWARE on FIRMWARE.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue RSA_IP_ADDRESS from cispec where cispec.assetattrid = 'RSA_IP_ADDRESS') RSA_IP_ADDRESS on RSA_IP_ADDRESS.CINUM = ci.cinum
  left join (select cinum, assetattrid, alnvalue STORAGE_IP_ADDRESS from cispec where cispec.assetattrid = 'STORAGE_IP_ADDRESS') STORAGE_IP_ADDRESS on STORAGE_IP_ADDRESS.CINUM = ci.cinum
  left join Asset on CI.ASSETNUM = ASSET.ASSETNUM
  join Classstructure on CI.CLASSSTRUCTUREID = Classstructure.CLASSSTRUCTUREID
  /* Runs On Cluster */
  left join (select cirelation.sourceci, CIRELATION.RELATIONNUM, TARGETCI.CINUM, TARGETCI.CINAME
              from cirelation
                join ci targetci on targetci.cinum = cirelation.targetci
              where TARGETCI.CLASSSTRUCTUREID in (select classstructureid from classstructure 
                                                  where description in ('CI.COMPUTERSYSTEMCLUSTER'))
            ) RUNSONCLUSTER on ci.cinum = RUNSONCLUSTER.sourceci
  /* Runs On Servers */
  left join (select cirelation.sourceci,
                    listagg(TARGETCI.CINAME, ', ') WITHIN GROUP (ORDER BY cirelation.sourceci) SERVERS
              from cirelation
                join ci targetci on targetci.cinum = cirelation.targetci
              where TARGETCI.CLASSSTRUCTUREID in (select classstructureid from classstructure 
                                                  where description in ('CI.PHYSICALCOMPUTERSYSTEM', 'CI.VIRTUALCOMPUTERSYSTEM', 'CI.COMPUTERSYSTEM'))
                and CIRELATION.RELATIONNUM = 'RELATION.RUNSON'
              group by cirelation.sourceci) RUNSONSERVERS on ci.cinum = RUNSONSERVERS.sourceci
  /* Uses Databases */
  left join (select cirelation.targetci,
                    listagg(sourceci.CINAME, ', ') WITHIN GROUP (ORDER BY cirelation.targetci) DATABASES
              from cirelation
                join ci sourceci on sourceci.cinum = cirelation.sourceci
              where sourceci.CLASSSTRUCTUREID in (select classstructureid from classstructure 
                                                  where description in ('CI.ORACLEDATABASE', 'CI.SQLSERVERDATABASE', 
                                                                        'CI.MSSQLSCHEMA', 'CI.ORACLEINSTANCE', 'CI.ORACLESCHEMA'))
                and CIRELATION.RELATIONNUM = 'RELATION.SUPPORTS'
              group by cirelation.targetci) USESDATABASES on ci.cinum = USESDATABASES.targetci
  /* Supports Applications */
  left join (select cirelation.sourceci,
                    listagg(targetci.CINAME, ', ') WITHIN GROUP (ORDER BY cirelation.sourceci) DATABASES
              from cirelation
                join ci targetci on targetci.cinum = cirelation.targetci
              where targetci.CLASSSTRUCTUREID in (select classstructureid from classstructure 
                                                  where description in ('CI.SOFTWARESERVICE', 'CI.SOFTWAREINSTALLATION', 'CI.SOFTWAREPRODUCT'))
                and CIRELATION.RELATIONNUM = 'RELATION.SUPPORTS'
              group by cirelation.sourceci) USESDATABASES on ci.cinum = USESDATABASES.sourceci
  /* All Relationships */
  left join (select 
              case when relationnum in ('RELATION.SUPPORTS') then targetci else sourceci end SOURCECI,
              listagg(replace(decode(relationnum, 'RELATION.SUPPORTS', 'RELATION.SUPPORTED_BY', relationnum), 'RELATION.', '') || ' ' || targetci.ciname, ', ') 
                WITHIN GROUP (ORDER BY targetci.ciname) CIRELATIONS
            from cirelation
              join ci SOURCECI on sourceci.cinum = case when relationnum in ('RELATION.SUPPORTS') then targetci else sourceci end
              join ci TARGETCI on targetci.cinum = case when relationnum in ('RELATION.SUPPORTS') then sourceci else targetci end
            group by case when relationnum in ('RELATION.SUPPORTS') then targetci else sourceci end
            ) ALLRELS on ALLRELS.sourceci = ci.cinum
  /* Details of changes against these CIs which are waiting for CI review */
  join (select MULTIASSETLOCCI.cinum, wochange.wonum, wochange.description, wochange.owner, wochange.ownergroup,
                wochange.schedstart, wochange.schedfinish, nodeid
              from MULTIASSETLOCCI
                join wochange on wochange.wonum = MULTIASSETLOCCI.recordkey
                join wfassignment on (wfassignment.ownerid = wochange.workorderid 
                                      and nodeid in (136, 137)
--                                      and assigncode = 'BDENSMOR' 
                                      and WFASSIGNMENT.ASSIGNSTATUS not in ('COMPLETE', 'FORWARDED', 'INACTIVE'))) CHANGES_FOR_REVIEW on CHANGES_FOR_REVIEW.cinum = ci.cinum
where 1=1
--  and ci.STATUS not in ('DECOMMISSIONED')
--  and ci.changeby = 'JKOZAK'
--  and CHANGES_FOR_REVIEW.owner = 'BHAUSAUE'
--  and CHANGES_FOR_REVIEW.ownergroup = 'LVS-NETWORK-OPS'
--  and changes_for_review.wonum in ('CH-7605')
  order by CHANGES_FOR_REVIEW.ownergroup, CHANGES_FOR_REVIEW.owner, CHANGES_FOR_REVIEW.wonum, ci.ciname
;



/*******************************************************************************
*  Active Server CIs and Assets
*******************************************************************************/

select *
from
  (select CI.CINAME, CI.CINUM, CI_CLASS.DESCRIPTION CI_CLASS, ci.status CI_STATUS, 
    ASSET.ASSETTAG as assetname, ASSET.ASSETNUM, upper(ASSET_CLASS.DESCRIPTION) ASSET_CLASS, asset.status ASSET_STATUS, ASSET.MANUFACTURER, ASSET.EX_MODEL, ASSET.SERIALNUM, 
    OPERATINGSYSTEM_NAME.OPERATINGSYSTEM_NAME, FIRMWARE.FIRMWARE, INTERNAL_IP_ADDRESS.INTERNAL_IP_ADDRESS, CI.CINUM CINUM2
  from ci
    left join asset on CI.ASSETNUM = ASSET.ASSETNUM
    left join CLASSSTRUCTURE CI_CLASS on CI_CLASS.CLASSSTRUCTUREID = CI.CLASSSTRUCTUREID
    left join CLASSSTRUCTURE ASSET_CLASS on ASSET_CLASS.CLASSSTRUCTUREID = ASSET.CLASSSTRUCTUREID
    left join (select cinum, assetattrid, alnvalue OPERATINGSYSTEM_NAME from cispec where cispec.assetattrid = 'OPERATINGSYSTEM_NAME') OPERATINGSYSTEM_NAME on OPERATINGSYSTEM_NAME.CINUM = ci.cinum
    left join (select cinum, assetattrid, alnvalue FIRMWARE from cispec where cispec.assetattrid = 'FIRMWARE') FIRMWARE on FIRMWARE.CINUM = ci.cinum
    left join (select cinum, assetattrid, alnvalue INTERNAL_IP_ADDRESS from cispec where cispec.assetattrid = 'INTERNAL_IP_ADDRESS') INTERNAL_IP_ADDRESS on INTERNAL_IP_ADDRESS.CINUM = ci.cinum
  union
  select CI.CINAME, CI.CINUM, CI_CLASS.DESCRIPTION CI_CLASS, ci.status CI_STATUS, 
    ASSET.ASSETTAG as assetname, ASSET.ASSETNUM, upper(ASSET_CLASS.DESCRIPTION) ASSET_CLASS, asset.status ASSET_STATUS, ASSET.MANUFACTURER, ASSET.EX_MODEL, ASSET.SERIALNUM, 
    OPERATINGSYSTEM_NAME.OPERATINGSYSTEM_NAME, FIRMWARE.FIRMWARE, INTERNAL_IP_ADDRESS.INTERNAL_IP_ADDRESS, CI.CINUM CINUM2
  from asset
    left join CI on ci.ASSETNUM = ASSET.ASSETNUM
    left join CLASSSTRUCTURE CI_CLASS on CI_CLASS.CLASSSTRUCTUREID = ci.CLASSSTRUCTUREID
    left join CLASSSTRUCTURE ASSET_CLASS on ASSET_CLASS.CLASSSTRUCTUREID = ASSET.CLASSSTRUCTUREID
    left join (select cinum, assetattrid, alnvalue OPERATINGSYSTEM_NAME from cispec where cispec.assetattrid = 'OPERATINGSYSTEM_NAME') OPERATINGSYSTEM_NAME on OPERATINGSYSTEM_NAME.CINUM = ci.cinum
    left join (select cinum, assetattrid, alnvalue FIRMWARE from cispec where cispec.assetattrid = 'FIRMWARE') FIRMWARE on FIRMWARE.CINUM = ci.cinum
    left join (select cinum, assetattrid, alnvalue INTERNAL_IP_ADDRESS from cispec where cispec.assetattrid = 'INTERNAL_IP_ADDRESS') INTERNAL_IP_ADDRESS on INTERNAL_IP_ADDRESS.CINUM = ci.cinum) ASSET_CI
where 
  1=1
--  and (ci_class is null or CI_CLASS in ('CI.VIRTUALCOMPUTERSYSTEM', 'CI.PHYSICALCOMPUTERSYSTEM', 'CI.SWITCH', 'CI.ROUTER', 'CI.FIREWALL'))
--  and (asset_class is null or asset_CLASS in ('PHYSICAL SERVER'))
--  and (ci_status not in ('DECOMMISSIONED')
--    or asset_status not in ('DECOMMISSIONED', 'DISPOSED'))
order by CI_CLASS, ASSET_CLASS
;

select *
from assetspec;