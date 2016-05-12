/*******************************************************************************
*  Pull SRs, Incidents, and Activities and UNION them into a single result.
*  
*  Only open records or records resolved or closed within the past 31 days are
*  returned
*******************************************************************************/

select 
  TICKET.CLASS,
  TICKET.TICKETID RECORDID,
  TICKET.AFFECTEDPERSON,
  TICKET.REPORTEDBY,
  TICKET.CREATEDBY,
  CREATEDPERSON.DISPLAYNAME CREATEDBY_NAME,
  TICKET.DESCRIPTION,
  TICKET.ORIGRECORDCLASS,
  TICKET.ORIGRECORDID,
  TICKET.INTERNALPRIORITY,
  TICKET.STATUS,
  TO_CHAR(TICKET.STATUSDATE, 'yyyy-MM-dd hh24:mi:ss') STATUSDATE,
  (select COUNT(*) from MAXIMO.TKSTATUS where TKSTATUS.STATUS = 'REOPEN' and TKSTATUS.TICKETID = TICKET.TICKETID) as REOPEN_COUNT,
  TICKET.OWNER,
  OWNERPERSON.DISPLAYNAME OWNER_NAME,
  TICKET.OWNERGROUP,
  TO_CHAR(TICKET.REPORTDATE, 'yyyy-MM-dd hh24:mi:ss') REPORTDATE,
  TO_CHAR(TICKET.ACTUALFINISH, 'yyyy-MM-dd hh24:mi:ss') ACTUALFINISH,
  CLASSPATH.CLASSPATH,
  TICKET.EX_SITUATION,
  TICKET.EXSOFTWARE,
  ASSET.ASSETTAG,
  CI.CINAME,
  TICKET.EXVIP,
  TICKET.EXVIPASSET
from MAXIMO.TICKET
  left join MAXIMO.ASSET on ASSET.ASSETNUM = TICKET.ASSETNUM
  left join MAXIMO.CI on CI.CINUM = TICKET.CINUM
  left join MAXIMO.PERSON CREATEDPERSON on CREATEDPERSON.PERSONID = TICKET.CREATEDBY
  left join MAXIMO.PERSON OWNERPERSON on OWNERPERSON.PERSONID = TICKET.OWNER
  join (select CLASSSTRUCTUREID, LISTAGG(ANCESTORCLASSID, ' \ ') within group (order by HIERARCHYLEVELS desc) as CLASSPATH from MAXIMO.CLASSANCESTOR group by CLASSSTRUCTUREID) CLASSPATH on CLASSPATH.CLASSSTRUCTUREID = TICKET.CLASSSTRUCTUREID
where TICKET.class in ('INCIDENT', 'SR')
  and TICKET.SITEID not in ( 'EX-EX' ) /* Exclude Facilities */
  /* Exclude Demand (1330) and HR (1280)*/
  and not exists
  (
    select 1
    from MAXIMO.CLASSANCESTOR
    where (ANCESTOR        in ('1330', '1280'))
      and (CLASSSTRUCTUREID = TICKET.CLASSSTRUCTUREID )
  )
  /* Exclude SRs used to create Incidents */
  and not exists
  (
    select 1 from MAXIMO.INCIDENT where ORIGRECORDID = TICKET.TICKETID
  )
  /* Exclude tickets resolved/closed more than 31 days ago */
  and 
    (
      (TICKET.STATUS in ( 'RESOLVED' , 'CLOSED' ) and TICKET.STATUSDATE >= sysdate - 31 )
      or ( TICKET.STATUS not in ( 'RESOLVED' , 'CLOSED' ))
    )
union
select 
  'ACTIVITY' CLASS,
  WOACTIVITY.WONUM RECORDID,
  (select AFFECTEDPERSON from MAXIMO.TICKET where TICKETID = WOACTIVITY.ORIGRECORDID) AFFECTEDPERSON,
  (select REPORTEDBY from MAXIMO.TICKET where TICKETID = WOACTIVITY.ORIGRECORDID) REPORTEDBY,
  WOSTATUS.CHANGEBY CREATEDBY,
  CREATEDPERSON.DISPLAYNAME CREATEDBY_NAME,
  WOACTIVITY.DESCRIPTION,
  WOACTIVITY.ORIGRECORDCLASS,
  WOACTIVITY.ORIGRECORDID,
  WOACTIVITY.WOPRIORITY INTERNALPRIORITY,
  WOACTIVITY.STATUS,
  TO_CHAR(WOACTIVITY.STATUSDATE, 'yyyy-MM-dd hh24:mi:ss') STATUSDATE,
  null as REOPEN_COUNT,  
  WOACTIVITY.OWNER,
  OWNERPERSON.DISPLAYNAME OWNER_NAME,
  WOACTIVITY.OWNERGROUP,
  TO_CHAR(WOACTIVITY.REPORTDATE, 'yyyy-MM-dd hh24:mi:ss') REPORTDATE,
  TO_CHAR(WOACTIVITY.ACTFINISH, 'yyyy-MM-dd hh24:mi:ss') ACTUALFINISH,
  CLASSPATH.CLASSPATH,
  'N/A' EX_SITUATION,
  'N/A' EXSOFTWARE,
  ASSET.ASSETTAG,
  CI.CINAME,
  'N/A' EXVIP,
  'N/A' EXVIPASSET
from MAXIMO.WOACTIVITY
  left join MAXIMO.ASSET on ASSET.ASSETNUM = WOACTIVITY.ASSETNUM
  left join MAXIMO.CI on CI.CINUM = WOACTIVITY.CINUM
  left join MAXIMO.PERSON CREATEDPERSON on CREATEDPERSON.PERSONID = WOACTIVITY.CHANGEBY
  left join MAXIMO.PERSON OWNERPERSON on OWNERPERSON.PERSONID = WOACTIVITY.OWNER
  join MAXIMO.WOSTATUS on (WOSTATUS.WONUM = WOACTIVITY.WONUM and WOSTATUSID = (select min(WS.WOSTATUSID) from MAXIMO.WOSTATUS WS where WS.WONUM = WOACTIVITY.WONUM))
  left join (select CLASSSTRUCTUREID, LISTAGG(ANCESTORCLASSID, ' \ ') within group (order by HIERARCHYLEVELS desc) as CLASSPATH from MAXIMO.CLASSANCESTOR group by CLASSSTRUCTUREID) CLASSPATH on CLASSPATH.CLASSSTRUCTUREID = WOACTIVITY.CLASSSTRUCTUREID
where 
  /* Exclude activities cancelled, closed, completed, or failed more than 31 days ago */
  (
    (WOACTIVITY.STATUS in ( 'CAN' , 'CLOSE' , 'COMP' , 'FAIL' ) and WOACTIVITY.STATUSDATE >= sysdate - 31 )
    or ( WOACTIVITY.STATUS not in ( 'CAN' , 'CLOSE' , 'COMP' , 'FAIL' ))
  )
  and WOACTIVITY.ORIGRECORDCLASS in ('SR', 'INCIDENT')
;