/*******************************************************************************
*  Tickets with Workstation or Mobile CANIS IDs in the summary or description
*******************************************************************************/

select 
  ',='||ticket.ticketid ticketid, Ticket.Status, ticket.reportdate, Ticket.Ownergroup, Ticket.Owner, 
  replace(REGEXP_SUBSTR(upper(ticket.description), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', '') SUMMARY_WS_CANIS,
  SUM_WS_ASSET.assetnum SUMMARY_ASSETNUM,
  replace(REGEXP_SUBSTR(upper(Longdescription.Ldtext), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', '') DETAILS_WS_CANIS,
  DET_WS_ASSET.assetnum DETAILS_ASSETNUM,
  replace(REGEXP_SUBSTR(ticket.description, '6[0-9]{5}'), ' ', '') SUMMARY_MOB_CANIS,
  SUM_MOB_ASSET.assetnum SUMMARY_ASSETNUM,
  replace(REGEXP_SUBSTR(REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' '), '6[0-9]{5}'), ' ', '') DETAILS_MOB_CANIS,
  DET_MOB_ASSET.assetnum DETAILS_ASSETNUM
from ticket
  join Longdescription on Longdescription.ldkey = Ticket.Ticketuid
  join classstructure on Classstructure.Classstructureid = Ticket.Classstructureid
  left join asset SUM_WS_ASSET on SUM_WS_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(upper(ticket.description), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', ''))
  left join asset DET_WS_ASSET on DET_WS_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(upper(Longdescription.Ldtext), 'E[A-Z]{2}\s*[0-9]{5}'), ' ', ''))
  left join asset SUM_MOB_ASSET on SUM_MOB_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(ticket.description, '6[0-9]{5}'), ' ', ''))
  left join asset DET_MOB_ASSET on DET_MOB_ASSET.assettag = to_char(replace(REGEXP_SUBSTR(REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' '), '6[0-9]{5}'), ' ', ''))
where Longdescription.Ldownertable = 'TICKET'
  and Longdescription.LDOWNERCOL = 'DESCRIPTION'
--  and ticket.reportdate >= sysdate - 90
  and ticket.assetnum = 'NOTFOUND'
  and ticket.status != 'CLOSED'
  and
    (
    (REGEXP_LIKE(upper(ticket.description), 'E[A-Z]{2}\s*[0-9]{5}'))
    or
    (REGEXP_LIKE(upper(Longdescription.Ldtext), 'E[A-Z]{2}\s*[0-9]{5}'))
    or
    (REGEXP_LIKE(ticket.description, '6[0-9]{5}'))
    or
    (REGEXP_LIKE(REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' '), '6[0-9]{5}'))
    )
   and ticket.reportdate>= to_date('18-SEP-2015 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
order by ticket.ticketid;


--REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' ')