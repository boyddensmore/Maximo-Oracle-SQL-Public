
/*******************************************************************************
* Find cases where ISSUE transactions did not decrease inventory balance.
*******************************************************************************/

select errrow.*, 
    case when abs(NEXT_transdate - SECONDNEXT_transdate) <= (5/24/60/60) then 'UNDER 5 MINS' else '' end next_trans_timing5,
    case when abs(NEXT_transdate - SECONDNEXT_transdate) <= (10/24/60/60) then 'UNDER 10 MINS' else '' end next_trans_timing10
from (select BCFINVTRANS.itemnum, BCFINVTRANS.transtype, to_char(BCFINVTRANS.transdate, 'yy-mm-dd hh24:mi:ss') transdate, BCFINVTRANS.enterby, BCFINVTRANS.bin, BCFINVTRANS.location,
        BCFINVTRANS.quantity, BCFINVTRANS.curbal, BCFINVTRANS.calcbal, 
        lead(BCFINVTRANS.curbal, 1) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) NEXT_CURBAL,
        lead(BCFINVTRANS.itemnum, 1) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) NEXT_ITEMNUM,
        lead(BCFINVTRANS.itemnum, 2) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) SECONDNEXT_ITEMNUM,
        lead(BCFINVTRANS.calcbal, 1) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) NEXT_calcbal,
        lead(BCFINVTRANS.transtype, 1) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) NEXT_transtype,
        lead(BCFINVTRANS.transdate, 1) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) NEXT_transdate,
        lead(BCFINVTRANS.transdate, 2) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) SECONDNEXT_transdate,
        BCFINVTRANS.fromstoreloc, BCFINVTRANS.tostoreloc, mrnum, wogroup, refwo, ponum
    from BCFINVTRANS
        left join inventory on (inventory.itemnum = bcfinvtrans.itemnum and inventory.location = 'CENTRAL')
    where 1=1
        and BCFINVTRANS.transdate >= to_date('01-03-2018 00:00', 'dd-mm-yyyy hh24:mi')
--        and BCFINVTRANS.transdate >= sysdate - (4/24)
--        and BCFINVTRANS.transdate <= to_date('01-03-2017 00:00', 'dd-mm-yyyy hh24:mi')
        and (BCFINVTRANS.fromstoreloc = 'CENTRAL' or BCFINVTRANS.tostoreloc = 'CENTRAL')
    order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate desc) ERRROW
where itemnum = NEXT_ITEMNUM
    and transtype = 'ISSUE'
--    and next_transtype not in ('RECBALADJ','PCOUNTADJ','AVGCSTADJ','CURBALADJ')
    and next_transtype not in ('RECBALADJ','PCOUNTADJ','CURBALADJ','TRANSFER','RECEIPT','RETURN','AVGCSTADJ')
    and curbal = next_curbal
--    and itemnum = '051661'
--    and itemnum in (select itemnum
--                    from matusetrans
--                    where IT1 in (7515, 7624, 7794, 7861, 7888, 8280, 8291, 8855))
--    and abs(NEXT_transdate - SECONDNEXT_transdate) > (5/24/60/60)

--    If the imbalance is between two transactions that are less than 5 seconds apart there's a high probability that they're part of the same batch and we're just seeing an out-of-order issue that looks like an imbalance.
    and (itemnum = SECONDNEXT_ITEMNUM and abs(NEXT_transdate - SECONDNEXT_transdate) > (5/24/60/60))
order by transdate desc
;


select to_char(matusetrans.transdate, 'yy-mm-dd hh24:mi:ss') transdate, matusetrans.* 
from matusetrans
where itemnum = '034067'
    and (storeloc = 'CENTRAL')
--    and refwo = 'CENT.1335945'
order by matusetrans.itemnum, matusetrans.transdate desc;


/*******************************************************************************
* Show last batch details
*******************************************************************************/

select matusetrans.IT1 batchnum, 
    matusetrans.itemnum, 
--    matusetrans.quantity,
    max(matusetrans.curbal) MAX_CURBAL,
    sum(matusetrans.quantity) QTY_SUM,
    (max(matusetrans.curbal) + sum(matusetrans.quantity)) TRANS_RESULT,
    invbalances.curbal INVBAL_CURBAL,
    case when (max(matusetrans.curbal) + sum(matusetrans.quantity)) <> invbalances.curbal then 'MISMATCH' else 'OK' end MATCH_FLAG
from matusetrans
    join invbalances on (matusetrans.itemnum = invbalances.itemnum and invbalances.location = 'CENTRAL')
where IT1 = (select max(to_number(IT1)) from matusetrans)
group by matusetrans.IT1, matusetrans.itemnum, invbalances.curbal
order by matusetrans.itemnum;





/*******************************************************************************
* For Maximo where clause
*******************************************************************************/

select *
from inventory 
where exists 
    (select 1
    from (select itemnum, transtype, curbal, 
            lead(curbal, 1) OVER (order by itemnum, transdate asc) NEXT_CURBAL,
            lead(itemnum, 1) OVER (order by itemnum, transdate asc) NEXT_ITEMNUM,
            lead(itemnum, 2) OVER (order by itemnum, transdate asc) SECONDNEXT_ITEMNUM,
            lead(transtype, 1) OVER (order by itemnum, transdate asc) NEXT_transtype,
            lead(BCFINVTRANS.transdate, 1) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) NEXT_transdate,
        lead(BCFINVTRANS.transdate, 2) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) SECONDNEXT_transdate
        from BCFINVTRANS
        where transdate >= to_date('01-01-2016 00:00', 'dd-mm-yyyy hh24:mi')
            and (fromstoreloc = 'CENTRAL' or tostoreloc = 'CENTRAL')
        order by itemnum, transdate desc) ERRROW
    where itemnum = NEXT_ITEMNUM
        and transtype = 'ISSUE'
        and next_transtype not in ('RECBALADJ','PCOUNTADJ','CURBALADJ','TRANSFER','RECEIPT','RETURN','AVGCSTADJ')
        and (itemnum = SECONDNEXT_ITEMNUM and abs(NEXT_transdate - SECONDNEXT_transdate) > (5/24/60/60))
        and curbal = next_curbal
        and ERRROW.itemnum = inventory.itemnum)
    and location = 'CENTRAL'
;


/*******************************************************************************
* For Escalation
*******************************************************************************/

select *
from inventory
where itemnum in (select itemnum
from (select BCFINVTRANS.itemnum, BCFINVTRANS.transtype,
        BCFINVTRANS.curbal,
        lead(BCFINVTRANS.curbal, 1) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) NEXT_CURBAL,
        lead(BCFINVTRANS.itemnum, 1) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) NEXT_ITEMNUM,
        lead(BCFINVTRANS.itemnum, 2) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) SECONDNEXT_ITEMNUM,
        lead(BCFINVTRANS.transtype, 1) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) NEXT_transtype,
        lead(BCFINVTRANS.transdate, 1) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) NEXT_transdate,
        lead(BCFINVTRANS.transdate, 2) OVER (order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate asc) SECONDNEXT_transdate,
        BCFINVTRANS.fromstoreloc, BCFINVTRANS.tostoreloc, mrnum, wogroup, refwo, ponum
    from BCFINVTRANS
        left join inventory on (inventory.itemnum = bcfinvtrans.itemnum and inventory.location = 'CENTRAL')
    where 1=1
        and BCFINVTRANS.transdate >= sysdate - 60
        and (BCFINVTRANS.fromstoreloc = 'CENTRAL' or BCFINVTRANS.tostoreloc = 'CENTRAL')
    order by BCFINVTRANS.itemnum, BCFINVTRANS.transdate desc) ERRROW
where itemnum = NEXT_ITEMNUM
    and transtype = 'ISSUE'
    and next_transtype not in ('RECBALADJ','PCOUNTADJ','AVGCSTADJ','CURBALADJ')
    and curbal = next_curbal
    and (itemnum = SECONDNEXT_ITEMNUM and abs(NEXT_transdate - SECONDNEXT_transdate) > (5/24/60/60)))
and location = 'CENTRAL'
;