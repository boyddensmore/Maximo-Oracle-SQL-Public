/*******************************************************************************
* Find older MRs with
* - No reservations
* - No PR/PO
* - Closed WO
*
* Add list of lines with POlines or POlines which haven't been received or issued, over 90 days
*******************************************************************************/

select 
    count(distinct mrnum) MRNUM_COUNT, count(mrlinenum) MRLINENUM_COUNT
--    mrline.mrnum, ', =' || mrline.mrnum groupselect, mrline.mrlinenum, mrline.itemnum, mrline.GLDEBITACCT, mrline.qty, mrline.directreq, mrline.complete, mrline.partialissue
from mrline
where 
    -- Parent MR is approved
    exists (select 1 from mr where mr.mrnum = mrline.mrnum and mr.siteid = mrline.siteid and mr.status = 'APPR')
    and mrline.requireddate <= sysdate - (30 * 6)
    and mrline.complete = 0
    -- No reservation exists for MRLine
    and not exists (select 1 from invreserve where mrnum = mrline.mrnum and mrlinenum = mrline.mrlinenum)
    -- No materials issued
    and not exists (select 1 from matusetrans where mrnum = mrline.mrnum and mrlinenum = mrline.mrlinenum)
--    and directreq = 0
--     No open PR
--    and not exists (select 1 from prline left join pr on (pr.prnum = prline.prnum and pr.status in ('WAPPR', 'APPR')) where mrnum = mrline.mrnum and mrlinenum = mrline.mrlinenum)
    -- No open PO
    and not exists (select 1 from poline left join po on (po.ponum = poline.ponum and po.status in ('WAPPR', 'APPR')) where mrnum = mrline.mrnum and mrlinenum = mrline.mrlinenum)
--    and rownum <= 10
--    and mrline.mrnum = 'CENT.16835'
order by mrline.mrnum, mrline.mrlinenum
;



select poline.ponum,  (select status from po where po.ponum = poline.ponum) POSTATUS,
    poline.polinenum, poline.itemnum, poline.storeloc,
    poline.mrnum, (select status from mr where mr.mrnum = poline.mrnum) MRSTATUS,
    poline.refwo, (select status from workorder where workorder.wonum = poline.refwo) WOSTATUS,
    poline.orderqty, poline.receivedqty,
    poline.receiptreqd, poline.receiptscomplete,
    matrectrans.issuetype RCPT_TYPE, matrectrans.transdate RCPT_TRANSDATE,  matrectrans.qtyrequested, matrectrans.quantity RCPT_QTY,
    case 
        when matrectrans.quantity = poline.orderqty then 'RCPT_COMPLETE' 
        when matrectrans.quantity < poline.orderqty then 'RCPT_UNDERFULFILLED'
        when matrectrans.quantity > poline.orderqty then 'RCPT_OVERFULFILLED'
        when matrectrans.quantity is null then 'RCPT_UNFULFILLED'
        else 'RCPT_UNKNOWN'
    end RCPT_COMPLETE,
    matusetrans.issuetype ISS_TYPE, matusetrans.transdate ISS_TRANDSATE, matusetrans.quantity ISS_QTY
from poline
    left join matusetrans on matusetrans.ponum = poline.ponum and matusetrans.polinenum = poline.polinenum
    left join matrectrans on matrectrans.ponum = poline.ponum and matrectrans.polinenum = poline.polinenum
where 1=1
    and exists (select 1 from po where po.ponum = poline.ponum and po.status in ('WAPPR', 'APPR'))
;

select physcnt, physcntdate
from invuseline
where invusenum = '1122'
    and invuselinenum = 1;