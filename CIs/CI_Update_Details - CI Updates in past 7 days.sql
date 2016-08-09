/*******************************************************************************
*  Set current connection schema to MAXIMO for report simplicity
*******************************************************************************/
alter session set current_schema = MAXIMO;


/*******************************************************************************
*  Show CIs with changes against them in the past X days with no updates to 
*  the CI
*******************************************************************************/

define TIMESPAN = "(24/24)";
define TIMESPAN = "21";
define TIMESPAN = "14";
define TIMESPAN = "7";


select configitem.cinum, configitem.ciname, configitem.changedate,
  addchg.wonum, addchg.owner, addchg.status, addchg.schedfinish, ADDCHG.DESCRIPTION
--  addchg.PMCHGTYPE, addchg.PMCHGCAT, addchg.JPNUM
from ci configitem
  join MULTIASSETLOCCI on MULTIASSETLOCCI.cinum = configitem.cinum
  join wochange addchg on (addchg.wonum = MULTIASSETLOCCI.recordkey and addchg.schedfinish >= sysdate - &TIMESPAN)
where configitem.CHANGEDATE < addchg.schedstart
  and (addchg.status in ('CLOSE', 'FAILPIR')
    or (addchg.status not in ('CAN') and addchg.schedfinish <= sysdate))
  and addchg.jpnum not in ('EX_STCH001', 'EX_STCH003', 'EX_STCH010', 'EX_STCH016', 'EX_STCH034', 'EX_STCH038', 'EX_STCH039')
  and not exists (select sourceci, TARGETCI, CHANGEDATE from CIRELATION where changedate > sysdate - &TIMESPAN and (configitem.CINUM = CIRELATION.SOURCECI or configitem.CINUM = CIRELATION.TARGETCI))
  and not exists (select cinum, changedate from cispec where changedate > sysdate - &TIMESPAN and configitem.CINUM = cispec.cinum)
order by ADDCHG.SCHEDFINISH desc;

/*******************************************************************************
*  Show CI update details from past X days
*******************************************************************************/
select CI.CINUM, CI.CINAME, CI.STATUS, CLASSSTRUCTURE.DESCRIPTION, CI.CHANGEBY , CI.CHANGEDATE, CI.RFC
from CI
  join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = CI.CLASSSTRUCTUREID
where CI.CHANGEDATE >= sysdate - &TIMESPAN
  and CI.CHANGEBY not in ('BDENSMOR', 'MXINTADM')
order by changedate desc;


/*******************************************************************************
*  Show relationship changes in the past X days
*******************************************************************************/

select CI.CINUM, CI.CINAME, SRCCI.CINAME SRCCI, CIRELATIONHIS.RELATIONNUM, TGTCI.CINAME TGTCI, 
  CIRELATIONHIS.STARTDATE, CIRELATIONHIS.ENDDATE, PERSON.DISPLAYNAME, PERSON.OWNERGROUP
from CI
  left join CIRELATIONHIS on (CI.CINUM = CIRELATIONHIS.SOURCECI or CI.CINUM = CIRELATIONHIS.TARGETCI)
  left join PERSON on PERSON.PERSONID = CIRELATIONHIS.CHANGEBY
  left join CI SRCCI on SRCCI.CINUM = CIRELATIONHIS.SOURCECI
  left join CI TGTCI on TGTCI.CINUM = CIRELATIONHIS.TARGETCI
where (STARTDATE >= sysdate - &TIMESPAN or ENDDATE >= sysdate - &TIMESPAN)
order by startdate desc;

/*******************************************************************************
*  Show spec changes in the past X days
*******************************************************************************/

select ci.CINUM, CI.CINAME, CI.CCIPERSONGROUP, CISPECHIS.ASSETATTRID,
  case when (CISPECHIS.ALNVALUE is null and CISPECHIS.NUMVALUE is not null) then to_char(CISPECHIS.NUMVALUE) else CISPECHIS.ALNVALUE end CURRVAL,
  case when (PREVVALUE.ALNVALUE is null and PREVVALUE.NUMVALUE is not null) then to_char(PREVVALUE.NUMVALUE) else PREVVALUE.ALNVALUE end PREVVAL,
  PERSON.DISPLAYNAME, PERSON.OWNERGROUP, CISPECHIS.CHANGEDATE, CISPECHIS.STARTDATE, CISPECHIS.ENDDATE
from CISPECHIS
  join ci on CISPECHIS.CINUM = CI.CINUM
  join PERSON on PERSON.PERSONID = CISPECHIS.CHANGEBY
  join CISPECHIS PREVVALUE on (PREVVALUE.CINUM = CISPECHIS.CINUM and prevvalue.ENDDATE = CISPECHIS.STARTDATE and PREVVALUE.ASSETATTRID = CISPECHIS.ASSETATTRID)
where 
  (CISPECHIS.STARTDATE >= sysdate - &TIMESPAN or CISPECHIS.ENDDATE >= sysdate - &TIMESPAN)
  and CISPECHIS.CISPECHISID in (select max(CISPECHISID) from CISPECHIS maxhis where maxhis.cinum = CISPECHIS.cinum and MAXHIS.ASSETATTRID = CISPECHIS.ASSETATTRID)
--  ci.cinum = '10008'  
order by CISPECHIS.CINUM, CISPECHIS.ASSETATTRID, CISPECHIS.CHANGEDATE;


/*******************************************************************************
*  CI Audit History records from past 7 days
*******************************************************************************/

select cinum, ciname, assetnum, classstructureid, description, EX_AUTHCIAPPSUPPCONTACT, EX_AUTHCIBUOWNER, EX_AUTHCINETWORK, EX_AUTHCISYSTEMCONTACT, PMCCIIMPACT, 
  to_char(EAUDITTIMESTAMP, 'dd-Mon-yy hh24:mi:ss'), EAUDITUSERNAME, PERSON.OWNERGROUP, EAUDITTYPE
from a_ci
  join person on A_CI.EAUDITUSERNAME = PERSON.PERSONID
where EAUDITTIMESTAMP >= sysdate - &TIMESPAN;


/*******************************************************************************
*  CIs created in past 7 days
*******************************************************************************/

select ',='||A_CI.cinum, A_CI.ciname, A_CI.assetnum, A_CI.classstructureid, A_CI.description, A_CI.EX_AUTHCIAPPSUPPCONTACT, A_CI.EX_AUTHCIBUOWNER, 
  A_CI.EX_AUTHCINETWORK, A_CI.EX_AUTHCISYSTEMCONTACT, A_CI.PMCCIIMPACT,
  to_char(A_CI.EAUDITTIMESTAMP, 'dd-Mon-yy hh24:mi:ss') EAUDITTIMESTAMP, A_CI.EAUDITUSERNAME, 
  PERSON.OWNERGROUP, A_CI.EAUDITTYPE
from a_ci
  join ci on (CI.CINUM = A_CI.CINUM)
  join person on A_CI.EAUDITUSERNAME = PERSON.PERSONID
where A_CI.EAUDITTIMESTAMP >= sysdate - &TIMESPAN
  and A_CI.EAUDITTYPE = 'I';