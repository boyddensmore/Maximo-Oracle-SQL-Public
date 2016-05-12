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

