/*******************************************************************************
*  Tickets with Workstation or Mobile CANIS IDs in the summary or description
*******************************************************************************/

select 
  ',='||ticket.ticketid ticketid, ticket.ticketid, Ticket.Status, ticket.reportdate, Ticket.Ownergroup, Ticket.Owner, 
--  replace(REGEXP_SUBSTR(upper(ticket.description), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', '') SUMMARY_WS_CANIS,
  SUM_WS_ASSET.assetnum SUMMARY_ASSETNUM,
--  replace(REGEXP_SUBSTR(upper(Longdescription.Ldtext), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', '') DETAILS_WS_CANIS,
  DET_WS_ASSET.assetnum DETAILS_ASSETNUM,
--  replace(REGEXP_SUBSTR(ticket.description, '6[0-9]{5}'), ' ', '') SUMMARY_MOB_CANIS,
  SUM_MOB_ASSET.assetnum SUMMARY_ASSETNUM,
--  replace(REGEXP_SUBSTR(REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' '), '6[0-9]{5}'), ' ', '') DETAILS_MOB_CANIS,
  DET_MOB_ASSET.assetnum DETAILS_ASSETNUM,
  case when SUM_WS_ASSET.assetnum is null then
    case when DET_WS_ASSET.assetnum is null then
      case when SUM_MOB_ASSET.assetnum is null then
        case when DET_MOB_ASSET.assetnum is null then 
        null else DET_MOB_ASSET.assetnum end
      else SUM_MOB_ASSET.assetnum end
    else DET_WS_ASSET.assetnum end
  else SUM_WS_ASSET.assetnum end THEASSETNUM
from ticket
  join Longdescription on Longdescription.ldkey = Ticket.Ticketuid
  join classstructure on Classstructure.Classstructureid = Ticket.Classstructureid
  left join asset SUM_WS_ASSET on SUM_WS_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(upper(ticket.description), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', ''))
  left join asset DET_WS_ASSET on DET_WS_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(upper(Longdescription.Ldtext), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', ''))
  left join asset SUM_MOB_ASSET on SUM_MOB_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(ticket.description, '6[0-9]{5}'), ' ', ''))
  left join asset DET_MOB_ASSET on DET_MOB_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' '), '6[0-9]{5}'), ' ', ''))
where Longdescription.Ldownertable = 'TICKET'
  and Longdescription.LDOWNERCOL = 'DESCRIPTION'
--  and ticket.reportdate >= sysdate - 150
--  and ticket.ticketid in ('IN-7932', 'IN-7936')
  and ticket.assetnum = 'NOTFOUND'
--  and ticket.status != 'CLOSED'
--  and
--    (
--    (REGEXP_LIKE(upper(ticket.description), 'E[A-Z]{2}\s*[0-9]{5}'))
--    or
--    (REGEXP_LIKE(upper(Longdescription.Ldtext), 'E[A-Z]{2}\s*[0-9]{5}'))
--    or
--    (REGEXP_LIKE(ticket.description, '6[0-9]{5}'))
--    or
--    (REGEXP_LIKE(REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' '), '6[0-9]{5}'))
--    )
--  and
--    (
--      SUM_WS_ASSET.assetnum is not null or
--      DET_WS_ASSET.assetnum is not null or
--      SUM_MOB_ASSET.assetnum is not null or
--      DET_MOB_ASSET.assetnum is not null
--    )
   and ticket.reportdate>= to_date('18-SEP-2015 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
   and rownum <= 50
order by ticket.ticketid;



/*******************************************************************************
*  UPDATE Tickets with Workstation or Mobile CANIS IDs in the summary or description
*******************************************************************************/

update ticket TK_TO_UPDATE
set TK_TO_UPDATE.assetnum = 
  (
    select 
      case when SUM_WS_ASSET.assetnum is null then
        case when DET_WS_ASSET.assetnum is null then
          case when SUM_MOB_ASSET.assetnum is null then
            case when DET_MOB_ASSET.assetnum is null then 
            null else DET_MOB_ASSET.assetnum end
          else SUM_MOB_ASSET.assetnum end
        else DET_WS_ASSET.assetnum end
      else SUM_WS_ASSET.assetnum end THEASSETNUM
    from ticket
      join Longdescription on Longdescription.ldkey = Ticket.Ticketuid
      join classstructure on Classstructure.Classstructureid = Ticket.Classstructureid
      left join asset SUM_WS_ASSET on SUM_WS_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(upper(ticket.description), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', ''))
      left join asset DET_WS_ASSET on DET_WS_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(upper(Longdescription.Ldtext), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', ''))
      left join asset SUM_MOB_ASSET on SUM_MOB_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(ticket.description, '6[0-9]{5}'), ' ', ''))
      left join asset DET_MOB_ASSET on DET_MOB_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' '), '6[0-9]{5}'), ' ', ''))
    where Longdescription.Ldownertable = 'TICKET'
      and Longdescription.LDOWNERCOL = 'DESCRIPTION'
      and ticket.ticketuid = TK_TO_UPDATE.ticketuid
      and rownum = 1
  )
where 1=1
--  and TK_TO_UPDATE.reportdate >= sysdate - 140
--  and TK_TO_UPDATE.ticketid in ('IN-7932', 'IN-7936')
  and TK_TO_UPDATE.assetnum = 'NOTFOUND'
--  and TK_TO_UPDATE.reportdate>= to_date('18-SEP-2015 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
  and rownum <= 1000
;



/*******************************************************************************
*  Count of affected tickets
*******************************************************************************/

select count(*)
from ticket TK_TO_UPDATE
where 1=1
--  and TK_TO_UPDATE.reportdate >= sysdate - 240
  and TK_TO_UPDATE.assetnum = 'NOTFOUND'
--  and TK_TO_UPDATE.reportdate>= to_date('18-SEP-2015 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
;