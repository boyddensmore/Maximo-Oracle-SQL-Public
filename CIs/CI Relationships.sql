/*******************************************************************************
*  Find all CIs related to a CI
*******************************************************************************/

select ci.cinum, ci.ciname, ci.PMCCIIMPACT, ci.EX_SUPPORTCALENDAR, ci.status,
  CIRELATION.SOURCECI, CIRELATION.TARGETCI,
  case when CIRELATION.SOURCECI = ci.cinum then 'SOURCE' else 'TARGET' end cireldirection,
  case when CIRELATION.SOURCECI = ci.cinum then CIRELATION.targetci else CIRELATION.SOURCECI end OTHERCI
from ci
  join cirelation on (CIRELATION.SOURCECI = ci.cinum or CIRELATION.TARGETCI = ci.cinum)
order by ci.cinum
;


/*******************************************************************************
*  Find all CIs supporting a CI
*******************************************************************************/

select ci.cinum, ci.ciname, ci.PMCCIIMPACT, ci.EX_SUPPORTCALENDAR, ci.status,
  SRCSPEC.ALNVALUE,
  CIRELATION.SOURCECI, cirelation.relationnum, ',=' || CIRELATION.TARGETCI, 
  TGTSPEC.ALNVALUE,
  TARGETCI.CINAME, TARGETCI.STATUS, TARGETCI.PMCCIIMPACT, TARGETCI.EX_SUPPORTCALENDAR
from ci
  join cirelation on CIRELATION.SOURCECI = ci.cinum
  join ci targetci on targetci.cinum = CIRELATION.TARGETCI
  left join cispec srcspec on SRCSPEC.CINUM = CI.CINUM
  left join cispec tgtspec on TGTSPEC.CINUM = TARGETCI.CINUM
where cirelation.relationnum in ('RELATION.CONTAINS', 'RELATION.ACCESSES', 'RELATION.RUNSON')
  and (SRCSPEC.ASSETATTRID = 'ENVIRONMENT' or SRCSPEC.ASSETATTRID is null)
  and (TGTSPEC.ASSETATTRID = 'ENVIRONMENT' or TGTSPEC.ASSETATTRID is null)
  and CI.PMCCIIMPACT = 1
  and (CI.PMCCIIMPACT != TARGETCI.PMCCIIMPACT
    or (CI.EX_SUPPORTCALENDAR != TARGETCI.EX_SUPPORTCALENDAR
      and TARGETCI.EX_SUPPORTCALENDAR != 'GOLD'))
order by ci.cinum
;

select * from cispec;

/*******************************************************************************
*  Find all CIs that a CI supports
*******************************************************************************/

select ',=' || ci.cinum, ci.ciname, ci.PMCCIIMPACT, ci.EX_SUPPORTCALENDAR, ci.status,
  CIRELATION.SOURCECI, cirelation.relationnum, CIRELATION.TARGETCI, 
  TARGETCI.CINAME, TARGETCI.STATUS, TARGETCI.PMCCIIMPACT, TARGETCI.EX_SUPPORTCALENDAR
from ci
  join cirelation on CIRELATION.SOURCECI = ci.cinum
  join ci targetci on targetci.cinum = CIRELATION.TARGETCI
  left join cispec srcspec on SRCSPEC.CINUM = CI.CINUM
  left join cispec tgtspec on TGTSPEC.CINUM = TARGETCI.CINUM
where cirelation.relationnum in ('RELATION.SUPPORTS')
  and TARGETCI.PMCCIIMPACT = 1
  and (TARGETCI.PMCCIIMPACT != CI.PMCCIIMPACT
    or (TARGETCI.EX_SUPPORTCALENDAR != CI.EX_SUPPORTCALENDAR
      and CI.EX_SUPPORTCALENDAR != 'GOLD'))
order by ci.cinum
;



/*******************************************************************************
*  Recursive analysis of CI impacts and calendars through relationships
*  Service <-- Infrastructure
*******************************************************************************/

select 
  case when LEAF_impact <= ROOT_IMPACT then 'OK' else 'NOT OK' end IMPACT_CHAIN_OK,
  case when LEAF_CALNUM <= ROOT_CALNUM then 'OK' else 'NOT OK' end CAL_CHAIN_OK,
  CORE_DATA.*
from (
  select 
    connect_by_root TGT_NAME ROOT_CI, 
    connect_by_root TGT_CLASS ROOT_CLASS,
    connect_by_root TGT_IMPACT ROOT_IMPACT,
    connect_by_root TGT_SUPPCALENDAR ROOT_CALENDAR,
    connect_by_root decode('BRONZE', TGT_SUPPCALENDAR, '3', decode('SILVER', TGT_SUPPCALENDAR, '2', decode('GOLD', TGT_SUPPCALENDAR, '1', TGT_SUPPCALENDAR))) ROOT_CALNUM,
    connect_by_root TGT_ENVIRONMENT ROOT_ENVIRONMENT,
    LEVEL LVL, 
    substr(SYS_CONNECT_BY_PATH(TGT_IMPACT, ', '), 3) || ', ' || SRC_IMPACT "IMPACT_ANL",
    substr(SYS_CONNECT_BY_PATH(decode('BRONZE', TGT_SUPPCALENDAR, '3', decode('SILVER', TGT_SUPPCALENDAR, '2', decode('GOLD', TGT_SUPPCALENDAR, '1', TGT_SUPPCALENDAR))), ', '), 3) || ', ' || decode('BRONZE', SRC_SUPPCALENDAR, '3', decode('SILVER', SRC_SUPPCALENDAR, '2', decode('GOLD', SRC_SUPPCALENDAR, '1', SRC_SUPPCALENDAR))) "CALENDAR_ANL",
    substr(SYS_CONNECT_BY_PATH(TGT_NAME, ' <-- '), 6) || ' <-- ' || SRC_NAME "CIHIERARCHY",
    SRC_NUM LEAF_CINUM,
    src_name LEAF_NAME,
    SRC_CLASS LEAF_CLASS,
    SRC_ENVIRONMENT LEAF_ENVIRONMENT,
    SRC_IMPACT LEAF_IMPACT,
    SRC_SUPPCALENDAR LEAF_SUPPCALENDAR,
    decode('BRONZE', SRC_SUPPCALENDAR, '3', decode('SILVER', SRC_SUPPCALENDAR, '2', decode('GOLD', SRC_SUPPCALENDAR, '1', SRC_SUPPCALENDAR))) LEAF_CALNUM
  from 
    (select CI.CINUM SRC_NUM, CI.CINAME SRC_NAME, SRC_CLASS.DESCRIPTION SRC_CLASS, CI.STATUS SRC_STATUS, CI.DESCRIPTION SRC_DESC,
      ci.PMCCIIMPACT SRC_IMPACT, ci.EX_SUPPORTCALENDAR SRC_SUPPCALENDAR,
      SRC_ENVIRONMENT.environment SRC_ENVIRONMENT,
      targetci.cinum TGT_NUM,
      targetci.ciname TGT_NAME,
      TGT_CLASS.DESCRIPTION TGT_CLASS,
      TGT_ENVIRONMENT.environment TGT_ENVIRONMENT,
      targetci.PMCCIIMPACT TGT_IMPACT, targetci.EX_SUPPORTCALENDAR TGT_SUPPCALENDAR
    from ci
      join Classstructure SRC_CLASS on CI.CLASSSTRUCTUREID = SRC_CLASS.CLASSSTRUCTUREID
      join (select 
              case when CIRELATION.relationnum = 'RELATION.SUPPORTS' then CIRELATION.sourceci else CIRELATION.targetci end SOURCECI,
              case when CIRELATION.relationnum = 'RELATION.SUPPORTS' then CIRELATION.targetci else CIRELATION.sourceci end TARGETCI,
              CIRELATION.relationnum
            from CIRELATION) RELATEDCI on ci.cinum = RELATEDCI.sourceci
      join ci targetci on (targetci.cinum = RELATEDCI.TARGETCI and targetci.status not in ('DECOMMISSIONED'))
      left join (select cinum, assetattrid, alnvalue ENVIRONMENT from cispec where cispec.assetattrid = 'ENVIRONMENT') SRC_ENVIRONMENT on SRC_ENVIRONMENT.CINUM = ci.cinum
      left join (select cinum, assetattrid, alnvalue ENVIRONMENT from cispec where cispec.assetattrid = 'ENVIRONMENT') TGT_ENVIRONMENT on TGT_ENVIRONMENT.CINUM = targetci.cinum
      join Classstructure TGT_CLASS on targetci.CLASSSTRUCTUREID = TGT_CLASS.CLASSSTRUCTUREID
      join (select distinct relationnum, NVL(SUBSTR(relationnum, INSTR(relationnum, '.')+1, length(relationnum)), relationnum) connector from cirelation) relconnector on relconnector.relationnum = RELATEDCI.RELATIONNUM
    where 1=1
      and ci.STATUS not in ('DECOMMISSIONED')
    order by ci.cinum) CIS
  connect by nocycle prior SRC_NUM = TGT_NUM
--  SYS_CONNECT_BY_PATH(SRC_NAME || ' ' || connector, ' > ')
) CORE_DATA
where 1=1
--  and CORE_DATA.ROOT_CI like 'MAXIMO%'
--  and lvl = 1
--  and root_impact = 1
--  and (src_impact > ROOT_IMPACT or SRC_CALNUM > ROOT_CALNUM)
--  and ROOT_CLASS not in ('CI.COMPUTERSYSTEMCLUSTER', 'CI.MSSQLSCHEMA', 'CI.VIRTUALCOMPUTERSYSTEM')
order by ROOT_CLASS, ROOT_CI, CIHIERARCHY
;



/*******************************************************************************
*  Recursive analysis of CI impacts and calendars through relationships
*  Infrastructure --> Service
*******************************************************************************/

select 
  case when LEAF_impact <= ROOT_IMPACT then 'OK' else 'NOT OK' end IMPACT_CHAIN_OK,
  case when LEAF_CALNUM <= ROOT_CALNUM then 'OK' else 'NOT OK' end CAL_CHAIN_OK,
  CORE_DATA.*
from (
  select 
    connect_by_root TGT_NAME ROOT_CI, 
    connect_by_root TGT_CLASS ROOT_CLASS,
    connect_by_root TGT_IMPACT ROOT_IMPACT,
    connect_by_root TGT_SUPPCALENDAR ROOT_CALENDAR,
    connect_by_root decode('BRONZE', TGT_SUPPCALENDAR, '3', decode('SILVER', TGT_SUPPCALENDAR, '2', decode('GOLD', TGT_SUPPCALENDAR, '1', TGT_SUPPCALENDAR))) ROOT_CALNUM,
    connect_by_root TGT_ENVIRONMENT ROOT_ENVIRONMENT,
    LEVEL LVL, 
    substr(SYS_CONNECT_BY_PATH(TGT_IMPACT, ', '), 3) || ', ' || SRC_IMPACT "IMPACT_ANL",
    substr(SYS_CONNECT_BY_PATH(decode('BRONZE', TGT_SUPPCALENDAR, '3', decode('SILVER', TGT_SUPPCALENDAR, '2', decode('GOLD', TGT_SUPPCALENDAR, '1', TGT_SUPPCALENDAR))), ', '), 3) || ', ' || decode('BRONZE', SRC_SUPPCALENDAR, '3', decode('SILVER', SRC_SUPPCALENDAR, '2', decode('GOLD', SRC_SUPPCALENDAR, '1', SRC_SUPPCALENDAR))) "CALENDAR_ANL",
    substr(SYS_CONNECT_BY_PATH(TGT_NAME, ' <-- '), 6) || ' <-- ' || SRC_NAME "CIHIERARCHY",
    SRC_NUM LEAF_CINUM,
    src_name LEAF_NAME,
    SRC_CLASS LEAF_CLASS,
    SRC_ENVIRONMENT LEAF_ENVIRONMENT,
    SRC_IMPACT LEAF_IMPACT,
    SRC_SUPPCALENDAR LEAF_CALENDAR,
    decode('BRONZE', SRC_SUPPCALENDAR, '3', decode('SILVER', SRC_SUPPCALENDAR, '2', decode('GOLD', SRC_SUPPCALENDAR, '1', SRC_SUPPCALENDAR))) LEAF_CALNUM
  from 
    (select CI.CINUM SRC_NUM, CI.CINAME SRC_NAME, SRC_CLASS.DESCRIPTION SRC_CLASS, CI.STATUS SRC_STATUS, CI.DESCRIPTION SRC_DESC, 
      ci.PMCCIIMPACT SRC_IMPACT, ci.EX_SUPPORTCALENDAR SRC_SUPPCALENDAR,
      SRC_ENVIRONMENT.environment SRC_ENVIRONMENT,
      targetci.cinum TGT_NUM,
      targetci.ciname TGT_NAME,
      TGT_CLASS.DESCRIPTION TGT_CLASS,
      TGT_ENVIRONMENT.environment TGT_ENVIRONMENT,
      targetci.PMCCIIMPACT TGT_IMPACT, targetci.EX_SUPPORTCALENDAR TGT_SUPPCALENDAR
    from ci
      join Classstructure SRC_CLASS on CI.CLASSSTRUCTUREID = SRC_CLASS.CLASSSTRUCTUREID
      join (select 
              case when CIRELATION.relationnum = 'RELATION.SUPPORTS' then CIRELATION.sourceci else CIRELATION.targetci end TARGETCI,
              case when CIRELATION.relationnum = 'RELATION.SUPPORTS' then CIRELATION.targetci else CIRELATION.sourceci end SOURCECI,
              CIRELATION.relationnum
            from CIRELATION) RELATEDCI on ci.cinum = RELATEDCI.sourceci
      join ci targetci on (targetci.cinum = RELATEDCI.TARGETCI and targetci.status not in ('DECOMMISSIONED'))
      left join (select cinum, assetattrid, alnvalue ENVIRONMENT from cispec where cispec.assetattrid = 'ENVIRONMENT') SRC_ENVIRONMENT on SRC_ENVIRONMENT.CINUM = ci.cinum
      left join (select cinum, assetattrid, alnvalue ENVIRONMENT from cispec where cispec.assetattrid = 'ENVIRONMENT') TGT_ENVIRONMENT on TGT_ENVIRONMENT.CINUM = targetci.cinum
      join Classstructure TGT_CLASS on targetci.CLASSSTRUCTUREID = TGT_CLASS.CLASSSTRUCTUREID
      join (select distinct relationnum, NVL(SUBSTR(relationnum, INSTR(relationnum, '.')+1, length(relationnum)), relationnum) connector from cirelation) relconnector on relconnector.relationnum = RELATEDCI.RELATIONNUM
    where 1=1
      and ci.STATUS not in ('DECOMMISSIONED')
    order by ci.cinum) CIS
  connect by nocycle prior SRC_NUM = TGT_NUM
--  SYS_CONNECT_BY_PATH(SRC_NAME || ' ' || connector, ' > ')
) CORE_DATA
where 1=1
--  and CORE_DATA.ROOT_CI like 'LXSRV024'
--  and lvl = 1
--  and root_impact = 1
  and (LEAF_impact > ROOT_IMPACT or LEAF_CALNUM > ROOT_CALNUM)
  and ROOT_CLASS in ('CI.COMPUTERSYSTEMCLUSTER', 'CI.MSSQLSCHEMA', 'CI.ORACLESCHEMA', 'CI.VIRTUALCOMPUTERSYSTEM', 
                      'CI.PHYSICALCOMPUTERSYSTEM', 'CI.STORAGEARRAY', 'CI.STORAGEVOLUME', 'CI.SWITCH', 'CI.WINDOWSFILESYSTEM', 'VMware Data Store')
order by ROOT_CLASS, ROOT_CI, CIHIERARCHY
;