/*******************************************************************************
*  Maximo for IT queue details
*******************************************************************************/

-- Details
select ticket.TICKETID, ticket.EXRANK, ticket.INTERNALPRIORITY, 
  ticket.AFFECTEDPERSON, AFFECTEDPERSON.STATUS AFCT_PRSN_STAT,
  ticket.REPORTEDBY, REPORTEDPERSON.STATUS RPT_PRSN_STAT,
  OWNER, ticket.STATUS, ticket.EX_PENDINGREASON, ticket.REPORTDATE, ticket.DESCRIPTION summary,
  LONGDESCRIPTION.LDOWNERTABLE, LONGDESCRIPTION.LDOWNERCOL,
  REGEXP_REPLACE(LONGDESCRIPTION.LDTEXT,'<[^>]*>',' ') LONGDESCRIPTION,
  LONGDESCRIPTION.LDTEXT
from ticket
  left join LONGDESCRIPTION on (LONGDESCRIPTION.LDKEY = ticket.TICKETUID 
                                and LONGDESCRIPTION.LDOWNERTABLE = 'TICKET' 
                                and LONGDESCRIPTION.LDOWNERCOL = 'DESCRIPTION'
                                )
  left join person AFFECTEDPERSON on AFFECTEDPERSON.PERSONID = ticket.AFFECTEDPERSON
  left join person REPORTEDPERSON on REPORTEDPERSON.PERSONID = ticket.REPORTEDBY
where 
  TICKET.STATUS not in ('CLOSED', 'RESOLVED')
--  TICKET.STATUS in ('RESOLVED')
--  and OWNER in ('DPHUI', 'VJANKOVI', 'GBECK')
--  and owner = 'BDENSMOR'
and TICKET.ownergroup = 'MAXITSUPPORT'
order by ticket.EXRANK, ticket.INTERNALPRIORITY asc;




select ticketid,
  round(sum(
    (to_number(REGEXP_REPLACE(STATUSTRACKING,'(\d*)(:)(\d*)(:)(\d*)','\1')) * 60)
    +
    to_number(REGEXP_REPLACE(STATUSTRACKING,'(\d*)(:)(\d*)(:)(\d*)','\3'))
    +
    round(to_number(REGEXP_REPLACE(STATUSTRACKING,'(\d*)(:)(\d*)(:)(\d*)','\5')) / 60, 5)
  )) SLAHOLD_TOTAL_MINS
from TKSTATUS
where STATUS = 'SLAHOLD'
  and ownergroup = 'DESKSIDE'
group by ticketid;


select t1.ticketid, TO_CHAR(t1.changedate, 'dd-MON-yy hh24:mi:ss'), T1.OWNERGROUP,
  T2.TICKETID, TO_CHAR(t2.changedate, 'dd-MON-yy hh24:mi:ss'), t2.ownergroup
from tkstatus t1
  join tkstatus t2 on
    T1.TICKETID = T2.TICKETID
    and T2.OWNERGROUP != T1.OWNERGROUP
    and abs(T1.CHANGEDATE - T2.CHANGEDATE) < (120 / (24 * 60))
    and t1.status = t2.status
    and T2.CHANGEDATE > T1.CHANGEDATE
where T1.CHANGEDATE >= sysdate - 90
  and t1.status in ('INPROG')
  and t1.class = 'SR'
order by T1.TICKETID, T1.CHANGEDATE, T2.CHANGEDATE
;

select *
from
  (select t1.ticketid, count(*) CNT
  from tkstatus t1
    join tkstatus t2 on
      T1.TICKETID = T2.TICKETID
      and T2.OWNERGROUP != T1.OWNERGROUP
      and abs(T1.CHANGEDATE - T2.CHANGEDATE) < (20 / (24 * 60))
      and t1.status = t2.status
      and T2.CHANGEDATE > T1.CHANGEDATE
  where T1.CHANGEDATE >= sysdate - 90
    and t1.status in ('INPROG')
--    and t1.class = 'SR'
  group by t1.ticketid
  order by count(*) desc)
where CNT > 1
;

select *
from
  (select ticketid, count(*) TKCOUNT
  from tkstatus
  group by ticketid) TKS
where TKS.TKCOUNT > 17
;


/*******************************************************************************
*  Application CIs with related CIs
*******************************************************************************/

select APPCI.CINAME APP_NAME, APPENV.ENVIRONMENT APP_ENVIRONMENT, 
  '' WEB_CLIENT, '' DESKTOP_CLIENT, '' CITRIX_CLIENT, 
  BUS_IMPACT.DESCRIPTION BUS_IMPACT,  
  APPSVRCI.CINAME APPSERVER, SVRENV.ENVIRONMENT APPSERVER_ENV, SVRCLASS.CLASSIFICATIONID APPSERVER_CLASS,
  DBSRVCI.CINAME DBSERVER, DBSRVENV.ENVIRONMENT DBSERVER_ENV, DBSRVCLASS.CLASSIFICATIONID DBSERVER_CLASS,
  DBCI.CINAME DATABASE, DBENV.ENVIRONMENT DATABASE_ENV, DBCLASS.CLASSIFICATIONID DATABASE_CLASS,
--  listagg(
--    case when APPSVRCI.CINAME is not null then APPSVRCI.CINAME || ' (' || SVRENV.ENVIRONMENT || ', ' || SVRCLASS.CLASSIFICATIONID || ')' else null end
--    , chr(10)) within group (order by APPCI.CINAME, BUS_IMPACT.DESCRIPTION, APPCI.CCIPERSONGROUP, APPCLASS.CLASSIFICATIONID, APPENV.ENVIRONMENT) SERVER,
--  '' CITRIX_SERVER, '' OTHER_SERVER_PROCESSES,
--  listagg(
--    case when DBSRVCI.CINAME is not null then DBSRVCI.CINAME || ' (' || DBSRVENV.ENVIRONMENT || ', ' || DBSRVCLASS.CLASSIFICATIONID || ')' else null end
--    , chr(10)) within group (order by APPCI.CINAME, BUS_IMPACT.DESCRIPTION, APPCI.CCIPERSONGROUP, APPCLASS.CLASSIFICATIONID, APPENV.ENVIRONMENT) DATABASESERVER,
--  listagg(
--    case when DBCI.CINAME is not null then DBCI.CINAME || ' (' || DBENV.ENVIRONMENT || ', ' || DBCLASS.CLASSIFICATIONID || ')' else null end
--    , chr(10)) within group (order by APPCI.CINAME, BUS_IMPACT.DESCRIPTION, APPCI.CCIPERSONGROUP, APPCLASS.CLASSIFICATIONID, APPENV.ENVIRONMENT) DATABASES,
  APPCI.CCIPERSONGROUP SUPPORT_GROUP, APPCLASS.CLASSIFICATIONID APP_CLASS,
  '' FILE_SHARE, '' SYSTEM_INTEGRATION
from 
  -- Application
  CI APPCI
  join CLASSSTRUCTURE APPCLASS on (APPCLASS.CLASSSTRUCTUREID = APPCI.CLASSSTRUCTUREID
                      and APPCLASS.CLASSIFICATIONID like 'CI%SOFTWARE%')
  left join (select CINUM, ASSETATTRID, ALNVALUE ENVIRONMENT from CISPEC where CISPEC.ASSETATTRID = 'ENVIRONMENT') APPENV on APPENV.CINUM = APPCI.CINUM
  left join (select value, description from numericdomain where domainid = 'PMCCIIMPACT') BUS_IMPACT on BUS_IMPACT.value = APPCI.PMCCIIMPACT
  -- Related Server
  left join CIRELATION APPSVR_RELATION on APPSVR_RELATION.SOURCECI = APPCI.CINUM
  left join CI APPSVRCI on APPSVRCI.CINUM = APPSVR_RELATION.TARGETCI
  left join CLASSSTRUCTURE SVRCLASS on (SVRCLASS.CLASSSTRUCTUREID = APPSVRCI.CLASSSTRUCTUREID
                      and SVRCLASS.CLASSIFICATIONID like 'CI%COMPUTERSYSTEM%')
  left join (select CINUM, ASSETATTRID, ALNVALUE ENVIRONMENT from CISPEC where CISPEC.ASSETATTRID = 'ENVIRONMENT') SVRENV on SVRENV.CINUM = APPSVRCI.CINUM
  -- Related Database
  left join CIRELATION DB_RELATION on DB_RELATION.TARGETCI = APPCI.CINUM
  left join ci DBCI on DBCI.CINUM = DB_RELATION.SOURCECI
  left join classancestor DBCLASS on (DBCLASS.CLASSSTRUCTUREID = DBCI.CLASSSTRUCTUREID
                      and DBCLASS.ancestorclassid like '%DATABASE%')
  left join (select CINUM, ASSETATTRID, ALNVALUE ENVIRONMENT from CISPEC where CISPEC.ASSETATTRID = 'ENVIRONMENT') DBENV on DBENV.CINUM = DBCI.CINUM
  -- Database Server
  left join CIRELATION DBSRV_RELATION on DBSRV_RELATION.SOURCECI = DBCI.CINUM
  left join ci DBSRVCI on DBCI.CINUM = DBSRV_RELATION.TARGETCI
  left join classancestor DBSRVCLASS on (DBSRVCLASS.CLASSSTRUCTUREID = DBSRVCI.CLASSSTRUCTUREID
                      and (DBSRVCLASS.CLASSIFICATIONID like 'CI%COMPUTERSYSTEM%'))
  left join (select CINUM, ASSETATTRID, ALNVALUE ENVIRONMENT from CISPEC where CISPEC.ASSETATTRID = 'ENVIRONMENT') DBSRVENV on DBSRVENV.CINUM = DBSRVCI.CINUM
--group by APPCI.CINAME, BUS_IMPACT.DESCRIPTION, APPCI.CCIPERSONGROUP, APPCLASS.CLASSIFICATIONID, APPENV.ENVIRONMENT

;


select *
from cirelation SRCCI
  join (select cirelation.cirelationid, cirelation.sourceci targetci, cirelation.targetci sourceci, cirelation.relationnum
        from cirelation
        ) TGTCI on (TGTCI.sourceci = SRCCI.sourceci)
where SRCCI.sourceci = '10410';

select cirelationid
from cirelation
where sourceci = '10410' or targetci = '10410';

select 
  case when sourceci='6078' then sourceci else targetci end SOURCECI,
  case when sourceci='6078' then targetci else sourceci end TARGETCI,
  relationnum
from cirelation 
where sourceci='6078' or targetci='6078';






select TICKET.TICKETID, TICKET.CLASS, TICKET.AFFECTEDPERSON,
  CLASSHIERARCHY.HIERARCHYPATH,
  TICKET.DESCRIPTION,
  ticket.reportdate,
  ticket.internalpriority,
  ticket.targetfinish,
  ticket.status
from ticket
  left join
    (select classstructureid, listagg(ancestorclassid, ' / ') within group (order by hierarchylevels desc) HIERARCHYPATH from classancestor group by classstructureid) CLASSHIERARCHY on TICKET.CLASSSTRUCTUREID = CLASSHIERARCHY.CLASSSTRUCTUREID
where 
  ticket.class in ('SR', 'INCIDENT')
  and not exists (select *
                  from RELATEDRECORD
                  where class = 'SR' and RELATEDRECCLASS = 'INCIDENT' and relatetype = 'FOLLOWUP'
                    and relatedrecord.recordkey = ticket.ticketid)
  and ticket.status not in ('CLOSED', 'RESOLVED', 'CANCELED', 'REJECTED')
order by TICKET.TICKETID;



select persongroup.persongroup, PERSONGROUP.EX_MANAGER PERSONGROUP_MANAGER,
  PERSONGROUPTEAM.RESPPARTY GROUP_MEMBER, PERSON.DEPTDESC
from persongroup
  left join persongroupteam on PERSONGROUP.PERSONGROUP = PERSONGROUPTEAM.PERSONGROUP
  left join person on person.personid = PERSONGROUPTEAM.RESPPARTY
order by persongroup.persongroup, PERSONGROUPTEAM.RESPPARTY, PERSON.DEPTDESC;


select *
from WORKVIEW
where owner='BDENSMOR'
  and historyflag = 0
  and 
    (exists (select 1 from ticket where ticket.ticketid = workview.recordkey)
    or (exists (select 1 from ticket where ticket.ticketid = workview.recordkey)));
    
  


select 
--  ticket.ticketid, ticket.class, ticket.origrecordclass, ticket.origrecordid, ticket.reportdate, orig.reportdate, 
  case when ticket.reportdate = orig.reportdate then 'MATCH' else 'NO_MATCH' end RD_MATCH, count(*)
from ticket
  join ticket ORIG on TICKET.TICKETID = ORIG.TICKETID
where ticket.class = 'INCIDENT'
  and ticket.origrecordclass = 'SR'
group by case when ticket.reportdate = orig.reportdate then 'MATCH' else 'NO_MATCH' end
order by case when ticket.reportdate = orig.reportdate then 'MATCH' else 'NO_MATCH' end;



-- Get random records

SELECT *
FROM   (
    SELECT ownergroup, ticketid
    FROM   SR
    ORDER BY DBMS_RANDOM.RANDOM)
WHERE  rownum < 10;

select persongroup.persongroup, PG_TICKETS.ticketid 
from persongroup
left join
  (select *
  from
    (select ticketid, ownergroup
      from sr
      ORDER BY DBMS_RANDOM.RANDOM)
    WHERE  rownum < 10) PG_TICKETS on PG_TICKETS.ownergroup = persongroup.persongroup
order by persongroup;



select distinct person.personid, person.displayname, person.firstname, person.lastname
from persongroupteam
  join person on person.personid = persongroupteam.respparty;
  
  
select classstructureid, description
from classstructure
where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
  and (upper(description) like '%DESKTOP%'
    or upper(description) like '%LAPTOP%'
    or upper(description) like '%TABLET%'
    or upper(description) like '%SMART PHONE%'
    or upper(description) like '%MOBILE PHONE%');


select ci.cinum, ci.ciname, ci.status,
  TARGETREL.RELATIONNUM,
  target.cinum TGT_cinum, target.ciname TGT_ciname, 
  SOURCEREL.RELATIONNUM,
  source.cinum SRC_cinum, source.ciname SRC_ciname
from ci
  left join cirelation TARGETREL on CI.CINUM = TARGETREL.sourceci
  left join cirelation SOURCEREL on CI.CINUM = SOURCEREL.targetci
  left join ci target on TARGETREL.targetci = target.cinum
  left join ci source on SOURCEREL.targetci = source.cinum
--where ci.ciname = 'EECPRD'
order by ci.ciname
;



 




SELECT asset.assetnum, asset.description, classstructure.description,
  asset.status, ASSET.STATUSDATE, asset.manufacturer, asset.ex_model, asset.ex_other,
  asset.assettag, asset.serialnum, asset.LOCATION,
  locations.description location_description
FROM asset
  JOIN locations ON asset.LOCATION = locations.LOCATION
  join classstructure on classstructure.classstructureid = asset.classstructureid
WHERE asset.status IN ('DECOMMISSIONED', 'DISPOSED')
  and asset.classstructureid in (select classstructureid
                                from classstructure
                                where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                                  and (upper(description) like '%DESKTOP%'
                                    or upper(description) like '%LAPTOP%'
                                    or upper(description) like '%TABLET%'
                                    or upper(description) like '%SMART PHONE%'
                                    or upper(description) like '%MOBILE PHONE%'))
  and ASSET.STATUSDATE <= to_date('17-SEP-2015', 'dd-MON-yyyy')
ORDER BY assetnum;



select cinum, ciname, CCILINKRULENAME, changeby, changedate
from CI
where CCILINKRULENAME is not null;

select status, count(*)
from asset
where status not in ('DECOMMISSIONED', 'DISPOSED')
group by status
order by status;

select * 
from
  (select assetnum, assettag, status, rownum rnum
  from asset
  where status not in ('DECOMMISSIONED', 'DISPOSED'))
;



select PERSON.personid, PERSON.status, 
  PERSON.displayname, PERSON.location
--  ,
--  PERSON.statusdate, PERSON.sendersysid, PERSON.company, PERSON.deptdesc, 
--  PERSON.ex_businessunit, PERSON.ex_employeeid,
--   EXIF.EX_TRANSDATETIME, EXIF.status, EXIF.supervisor
from person
--  left join EXIFACE_WDAYPERSON EXIF on PERSON.PERSONID = EXIF.PERSONID
where person.supervisor = 'EKURCHIN'
--  and exif.supervisor != 'EKURCHIN'
order by person.personid 
--  ,EXIF.EX_TRANSDATETIME desc
;


select min(EX_TRANSDATETIME)
from EXIFACE_WDAYPERSON;



select wonum, transtype, transdate, nodetype, personid, actionperformed, memo
from wochange
  join wftransaction on (wftransaction.ownerid = wochange.workorderid and wftransaction.ownertable = 'WOCHANGE')
where wonum = 'CH-2867';


select *
from WFTRANSACTION
where ownertable = 'WOCHANGE';


select escalation, count(*)
from ESCSTATUS
where status not in ('SUCCESS')
--  and statusdate >= sysdate - 15
group by escalation
;

select reportname, reportfolder, to_char(lastrundate, 'dd-Mon-yyyy hh24:mi:ss'), lastrunby, lastrunduration
from report
where reportname like '%BDENSMOR%'
order by reportfolder, lastrundate desc;


select woactivity.wonum, woactivity.status, woactivity.changedate, woactivity.classstructureid, woactivity.description, 
  woactivity.origrecordid, woactivity.owner, woactivity.ownergroup, woactivity.reportedby, 
  to_char(woactivity.reportdate, 'dd-Mon-yyyy hh24:mi:ss') reportdate, to_char(woactivity.TARGSTARTDATE, 'dd-Mon-yyyy hh24:mi:ss') TARGSTARTDATE, 
  to_char(WOACTIVITY.TARGCOMPDATE, 'dd-Mon-yyyy hh24:mi:ss') TARGCOMPDATE,
  SLARECORDS.slanum, to_char(SLARECORDS.responsedate, 'dd-Mon-yyyy hh24:mi:ss') responsedate, to_char(SLARECORDS.resolutiondate, 'dd-Mon-yyyy hh24:mi:ss') resolutiondate,
  SLARECORDS.calccalendar, SLARECORDS.calcshift
from woactivity
  left join SLARECORDS on (SLARECORDS.ownertable = 'WORKORDER' and SLARECORDS.ownerid = woactivity.workorderid)
where wogroup = '21802';


select ticketid, status, statusdate
from sr
where not exists
  (select 1
  from incident
  where origrecordid = sr.ticketid)
  and 
  ((status in ('RESOLVED', 'CLOSED') and statusdate >= sysdate - 31) 
  or (status not in ('RESOLVED', 'CLOSED')));


select ticketid, status, statusdate
from incident
where 
  ((status in ('RESOLVED', 'CLOSED') and statusdate >= sysdate - 31) 
  or (status not in ('RESOLVED', 'CLOSED')));

select 
--  *
--  description, wogroup, WOCLASS
  woactivity.wonum, woactivity.status, woactivity.changedate, woactivity.description, 
  woactivity.wogroup,
  woactivity.origrecordid, woactivity.owner, woactivity.ownergroup, woactivity.reportedby, 
  reportdate, ACTFINISH
from woactivity
where 
  ((status in ('CAN', 'CLOSE', 'COMP', 'FAIL') and statusdate >= sysdate - 31) 
  or (status not in ('CAN', 'CLOSE', 'COMP', 'FAIL')));

select status, count(*)
from woactivity
where 
  ((status in ('CAN', 'CLOSE', 'COMP', 'FAIL') and statusdate >= sysdate - 31) 
  or (status not in ('CAN', 'CLOSE', 'COMP', 'FAIL')))
group by status;



-- Assets assigned to Deskside

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


select class, count(*)
from ticket
where assetnum = 'NOTFOUND'
  and status = 'RESOLVED'
  and ticket.reportdate>= to_date('18-SEP-2015 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
group by class;


select persongroup.persongroup, PERSONGROUP.EX_MANAGER PERSONGROUP_MANAGER,
  PERSONGROUPTEAM.RESPPARTY GROUP_MEMBER, PERSON.DEPTDESC
from persongroup
  left join persongroupteam on PERSONGROUP.PERSONGROUP = PERSONGROUPTEAM.PERSONGROUP
  left join person on person.personid = PERSONGROUPTEAM.RESPPARTY
order by persongroup.persongroup, PERSONGROUPTEAM.RESPPARTY, PERSON.DEPTDESC;




select 
  trunc(TICKETS.REPORTDATE, 'MON') REPORTDATE_MONTH,
  count(*) ALL_DS_OWN_COUNT,
  count(case when NOT EXISTS
  (
    SELECT 1
    FROM TKOWNERHISTORY
    WHERE OWNERGROUP NOT IN ('DESKSIDE')
      AND TKOWNERHISTORY.TICKETID = TICKETS.TICKETID
  ) then 1 else null end) ONLY_DS_OWN_COUNT,
  (count(*) - 
  count(case when NOT EXISTS
  (
    SELECT 1
    FROM TKOWNERHISTORY
    WHERE OWNERGROUP NOT IN ('DESKSIDE')
      AND TKOWNERHISTORY.TICKETID = TICKETS.TICKETID
  ) then 1 else null end)) DELTA
from ticket tickets
where EXISTS
  (SELECT 1
    FROM TKOWNERHISTORY
    WHERE OWNERGROUP IN ('DESKSIDE')
      AND TKOWNERHISTORY.TICKETID = TICKETS.TICKETID)
  and reportdate >= sysdate -120
group by trunc(TICKETS.REPORTDATE, 'MON')
order by trunc(TICKETS.REPORTDATE, 'MON')
;


select ',=' || wonum, status, EXCHGRESULT
from wochange
where (status = 'CLOSE' and exchgresult in ('REMPLAN', 'INCIDENT'))
  or (status = 'FAILPIR' and exchgresult not in ('REMPLAN', 'INCIDENT'));
  


select wochange.wonum, wochange.owner, wochange.ownergroup, wochange.assignedownergroup,
  PERSON.OWNERGROUP DEFAULT_GROUP
from wochange
  left join person on wochange.owner = PERSON.PERSONID
where wochange.wonum = 'CH-3463';


update wochange
set assignedownergroup = '', owner = ''
where wonum = 'CH-3463';