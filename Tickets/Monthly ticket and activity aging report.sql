select 
  ticket.class,
  TICKET.ticketid RECORDID,
  TICKET.Affectedperson,
  TICKET.Reportedby,
  Ticket.Createdby,
  CREATEDPERSON.DISPLAYNAME CREATEDBY_NAME,
  TICKET.Description,
  TICKET.Origrecordclass,
  TICKET.Origrecordid,
  TICKET.Internalpriority,
  TICKET.Status,
  to_char(TICKET.STATUSDATE, 'yyyy-MM-dd hh24:mi:ss') statusdate,
  (select count(*) from tkstatus where tkstatus.status = 'REOPEN' and tkstatus.ticketid = ticket.ticketid) as REOPEN_COUNT,
  TICKET.Owner,
  OWNERPERSON.DISPLAYNAME OWNER_NAME,
  TICKET.Ownergroup,
  to_char(TICKET.Reportdate, 'yyyy-MM-dd hh24:mi:ss') Reportdate,
  round(sysdate - TICKET.Reportdate, 1) DAYS_OPEN,
  to_char(TICKET.Actualfinish, 'yyyy-MM-dd hh24:mi:ss') actualfinish,
  classpath.classpath,
  TICKET.Ex_Situation,
  TICKET.Exsoftware,
  asset.assetnum,
  asset.assettag,
  ci.ciname,
  TICKET.Exvip,
  TICKET.Exvipasset
from MAXIMO.TICKET
  left join MAXIMO.Asset on asset.assetnum = ticket.assetnum
  left join MAXIMO.CI on CI.cinum = ticket.cinum
  left join MAXIMO.person createdperson on createdperson.personid = ticket.createdby
  left join MAXIMO.person ownerperson on ownerperson.personid = ticket.owner
  join (select classstructureid, LISTAGG(ANCESTORCLASSID, ' \ ') within group (order by hierarchylevels desc) as CLASSPATH from CLASSANCESTOR group by classstructureid) CLASSPATH on CLASSPATH.CLASSstructureid = TICKET.CLASSSTRUCTUREID
where ticket.class in ('INCIDENT', 'SR')
  and ticket.SITEID NOT IN ( 'EX-EX' ) /* Exclude Facilities */
  /* Exclude Demand (1330) and HR (1280)*/
  AND NOT EXISTS
  (
    SELECT 1
    FROM MAXIMO.CLASSANCESTOR
    WHERE (ANCESTOR        in ('1330', '1280'))
      AND (CLASSSTRUCTUREID = ticket.CLASSSTRUCTUREID )
  )
  /* Exclude SRs used to create Incidents */
  AND NOT EXISTS
  (
    SELECT 1 FROM INCIDENT WHERE ORIGRECORDID = ticket.TICKETID
  )
  AND ticket.STATUS NOT IN ( 'RESOLVED' , 'CLOSED' )
  and ticket.Reportdate <= sysdate - 5
union
select 
  'ACTIVITY' CLASS,
  woactivity.wonum RECORDID,
  (select affectedperson from ticket where ticketid = woactivity.origrecordid) affectedperson,
  (select reportedby from ticket where ticketid = woactivity.origrecordid) Reportedby,
  wostatus.changeby CREATEDBY,
  CREATEDPERSON.DISPLAYNAME CREATEDBY_NAME,
  woactivity.Description,
  woactivity.Origrecordclass,
  woactivity.Origrecordid,
  woactivity.WOPRIORITY Internalpriority,
  woactivity.Status,
  to_char(WOACTIVITY.STATUSDATE, 'yyyy-MM-dd hh24:mi:ss') statusdate,
  null as REOPEN_COUNT,  
  woactivity.Owner,
  OWNERPERSON.DISPLAYNAME OWNER_NAME,
  woactivity.Ownergroup,
  to_char(woactivity.Reportdate, 'yyyy-MM-dd hh24:mi:ss') Reportdate,
  round(sysdate - woactivity.Reportdate, 1) DAYS_OPEN,
  to_char(Woactivity.Actfinish, 'yyyy-MM-dd hh24:mi:ss') actualfinish,
  classpath.classpath,
  'N/A' Ex_Situation,
  'N/A' Exsoftware,
  asset.assetnum,
  asset.assettag,
  ci.ciname,
  'N/A' Exvip,
  'N/A' Exvipasset
from MAXIMO.woactivity
  left join MAXIMO.Asset on asset.assetnum = woactivity.assetnum
  left join MAXIMO.CI on CI.cinum = woactivity.cinum
  left join MAXIMO.person createdperson on createdperson.personid = woactivity.changeby
  left join MAXIMO.person ownerperson on ownerperson.personid = woactivity.owner
  join maximo.wostatus on (wostatus.wonum = woactivity.wonum and wostatusid = (select min(ws.wostatusid) from wostatus ws where ws.wonum = woactivity.wonum))
  left join (select classstructureid, LISTAGG(ANCESTORCLASSID, ' \ ') within group (order by hierarchylevels desc) as CLASSPATH from CLASSANCESTOR group by classstructureid) CLASSPATH on CLASSPATH.CLASSstructureid = woactivity.CLASSSTRUCTUREID
where 
  WOACTIVITY.STATUS NOT IN ( 'CAN' , 'CLOSE' , 'COMP' , 'FAIL' )
  and woactivity.Reportdate <= sysdate - 5
  and woactivity.Origrecordclass in ('SR', 'INCIDENT')
;