/*******************************************************************************
*  Tickets with Workstation or Mobile CANIS IDs in the summary or description
*******************************************************************************/

select 
  ',='||ticket.ticketid ticketid, ticket.ticketid, Ticket.Status, ticket.reportdate, Ticket.Ownergroup, Ticket.Owner,
  ticket.EX_CREATEDBYOWNRGRP, ticket.createdby,
  CLASSPATH.CLASSPATH,
--  SUM_WS_ASSET.assetnum SUMMARY_ASSETNUM,
  SUM_WS_ASSET.assettag SUMMARY_WS_ASSETTAG,
--  DET_WS_ASSET.assetnum DETAILS_ASSETNUM,
  DET_WS_ASSET.assettag DETAILS_WS_ASSETTAG,
--  SUM_MOB_ASSET.assetnum SUMMARY_ASSETNUM,
  SUM_MOB_ASSET.assettag SUMMARY_MOB_ASSETTAG,
--  DET_MOB_ASSET.assetnum DETAILS_ASSETNUM,
  DET_MOB_ASSET.assettag DETAILS_MOB_ASSETTAG,
  case when SUM_WS_ASSET.assetnum is null then
    case when DET_WS_ASSET.assetnum is null then
      case when SUM_MOB_ASSET.assetnum is null then
        case when DET_MOB_ASSET.assetnum is null then 
        null else DET_MOB_ASSET.assettag end
      else SUM_MOB_ASSET.assettag end
    else DET_WS_ASSET.assettag end
  else SUM_WS_ASSET.assettag end THEASSETTAG
from ticket
  join Longdescription on (Longdescription.ldkey = Ticket.Ticketuid and Longdescription.Ldownertable = 'TICKET' and Longdescription.LDOWNERCOL = 'DESCRIPTION')
  join classstructure on Classstructure.Classstructureid = Ticket.Classstructureid
  left join asset SUM_WS_ASSET on SUM_WS_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(upper(ticket.description), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', ''))
  left join asset DET_WS_ASSET on DET_WS_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(upper(Longdescription.Ldtext), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', ''))
  left join asset SUM_MOB_ASSET on SUM_MOB_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(ticket.description, '6[0-9]{5}'), ' ', ''))
  left join asset DET_MOB_ASSET on DET_MOB_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' '), '6[0-9]{5}'), ' ', ''))
  join (select classstructureid, LISTAGG(ANCESTORCLASSID, ' > ') within group (order by hierarchylevels desc) as CLASSPATH from maximo.CLASSANCESTOR group by classstructureid) CLASSPATH on CLASSPATH.CLASSstructureid = TICKET.CLASSSTRUCTUREID
where
  ticket.class in ('SR', 'INCIDENT')
  and ticket.assetnum is null
  and ticket.status != 'CLOSED'
  and ticket.ex_appname != 'EX_SR'
  and classpath.classpath not in ('REQUEST > SERVICE > PERSONEL > TERMINATION', 'REQUEST > HARDWARE > SERVER > REMOVE')
  and classpath.classpath not like ('% > HARDWARE > SERVER%')
  and classpath.classpath not like ('REQUEST > ACCESS%')
  and classpath.classpath not like ('REQUEST > SERVICE > PERSONEL%')
  and
    (
      SUM_WS_ASSET.assetnum is not null or
      DET_WS_ASSET.assetnum is not null or
      SUM_MOB_ASSET.assetnum is not null or
      DET_MOB_ASSET.assetnum is not null
    )
  and ticket.EX_CREATEDBYOWNRGRP = 'SERVICE DESK'
--    and ticket.EX_CREATEDBYOWNRGRP is null
order by ticket.ticketid;




/*******************************************************************************
*  Stats of creation months, groups, classifications
*******************************************************************************/

select 
  trunc(ticket.creationdate, 'MON') CREATION_MONTH,
  ticket.EX_CREATEDBYOWNRGRP,
--  CLASSPATH.CLASSPATH,
--  count(*) TICKETS_WITHOUT_ASSETNUM,
  count(case when SUM_WS_ASSET.assetnum is null then
    case when DET_WS_ASSET.assetnum is null then
      case when SUM_MOB_ASSET.assetnum is null then
        case when DET_MOB_ASSET.assetnum is null then 
        null else DET_MOB_ASSET.assetnum end
      else SUM_MOB_ASSET.assetnum end
    else DET_WS_ASSET.assetnum end
  else SUM_WS_ASSET.assetnum end) TICKETS_WITH_ASSET_IN_DETAILS
from ticket
  join Longdescription on (Longdescription.ldkey = Ticket.Ticketuid and Longdescription.Ldownertable = 'TICKET' and Longdescription.LDOWNERCOL = 'DESCRIPTION')
  join classstructure on Classstructure.Classstructureid = Ticket.Classstructureid
  left join asset SUM_WS_ASSET on SUM_WS_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(upper(ticket.description), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', ''))
  left join asset DET_WS_ASSET on DET_WS_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(upper(Longdescription.Ldtext), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', ''))
  left join asset SUM_MOB_ASSET on SUM_MOB_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(ticket.description, '6[0-9]{5}'), ' ', ''))
  left join asset DET_MOB_ASSET on DET_MOB_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' '), '6[0-9]{5}'), ' ', ''))
  left join ci on TICKET.CINUM = CI.CINUM
  join (select classstructureid, LISTAGG(ANCESTORCLASSID, ' > ') within group (order by hierarchylevels desc) as CLASSPATH from maximo.CLASSANCESTOR group by classstructureid) CLASSPATH on CLASSPATH.CLASSstructureid = TICKET.CLASSSTRUCTUREID
where
  ticket.class in ('SR', 'INCIDENT')
  and ticket.assetnum is null
--  and ticket.status != 'CLOSED'
  and ticket.ex_appname != 'EX_SR'
  and classpath.classpath not in ('REQUEST > SERVICE > PERSONEL > TERMINATION', 'REQUEST > HARDWARE > SERVER > REMOVE')
  and classpath.classpath not like ('% > HARDWARE > SERVER%')
  and classpath.classpath not like ('REQUEST > ACCESS%')
  and classpath.classpath not like ('REQUEST > SERVICE > PERSONEL%')
  and ticket.creationdate >= to_date('01-OCT-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
  and ticket.EX_CREATEDBYOWNRGRP = 'SERVICE DESK'
group by trunc(ticket.creationdate, 'MON'),
  ticket.EX_CREATEDBYOWNRGRP
--  CLASSPATH.CLASSPATH
order by trunc(ticket.creationdate, 'MON'),
  ticket.EX_CREATEDBYOWNRGRP
--  CLASSPATH.CLASSPATH
;