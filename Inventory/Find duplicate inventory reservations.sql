/********************************************************************
* Find duplicate inventory reservations
*  - Checks for same WO, MR, Item
*  - Excludes cases where the number of reservations is the same as the 
    number of Planned Material rows
*********************************************************************/

SELECT
    invreserve.wonum,
    WORKORDER.istask,
    WORKORDER.wogroup,
    invreserve.requestnum,
    invreserve.location,
    invreserve.itemnum,
    invreserve.requestedby,
    to_char(invreserve.requesteddate, 'yyyy-mm-dd hh24:mi:ss') requesteddate,
    to_char(invreserve.requireddate, 'yyyy-mm-dd hh24:mi:ss') requireddate,
    (SELECT COUNT(*)
            FROM maximo.invreserve dupreserv
            WHERE dupreserv.wonum = invreserve.wonum
                AND dupreserv.itemnum = invreserve.itemnum
            GROUP BY dupreserv.wonum, dupreserv.mrnum, dupreserv.itemnum
            HAVING COUNT(*) > 1
    ) reservation_count,
    (SELECT COUNT(*) FROM maximo.wpmaterial WHERE wpmaterial.itemnum = invreserve.itemnum AND wpmaterial.wonum = invreserve.wonum) wpmat_count,
    case when (SELECT requestnum FROM maximo.wpmaterial WHERE wpmaterial.itemnum = invreserve.itemnum AND wpmaterial.wonum = invreserve.wonum) = invreserve.requestnum then 'KEEP' else 'DELETE' end ACTION
FROM maximo.invreserve
    left join maximo.WORKORDER on WORKORDER.WONUM = INVRESERVE.WONUM
    left join maximo.wpmaterial on (wpmaterial.itemnum = invreserve.itemnum AND wpmaterial.wonum = invreserve.wonum)
WHERE EXISTS 
    (SELECT dupreserv.wonum, dupreserv.mrnum, dupreserv.itemnum, COUNT(*) cnt
            FROM maximo.invreserve dupreserv
            WHERE dupreserv.wonum = invreserve.wonum
                AND dupreserv.itemnum = invreserve.itemnum
            GROUP BY dupreserv.wonum, dupreserv.mrnum, dupreserv.itemnum
            HAVING COUNT(*) > 1)
    /* Check for cases where we have more than one reservation but that's expected based on WPMATERIAL */
    AND (SELECT COUNT(*) cnt
            FROM maximo.invreserve dupreserv
            WHERE dupreserv.wonum = invreserve.wonum
                AND dupreserv.itemnum = invreserve.itemnum
            GROUP BY dupreserv.wonum, dupreserv.mrnum, dupreserv.itemnum
            HAVING COUNT(*) > 1) 
        !=
        (SELECT COUNT(*) FROM maximo.wpmaterial WHERE wpmaterial.itemnum = invreserve.itemnum AND wpmaterial.wonum = invreserve.wonum)
/* WHERE2 CLAUSE */    
    -- where2 
    and invreserve.location = 'CENTRAL'
/* WHERE2 CLAUSE */    
ORDER BY invreserve.mrnum, invreserve.wonum, 
    invreserve.itemnum,
    invreserve.requestnum,
    invreserve.requestedby, invreserve.requesteddate, invreserve.requireddate, invreserve.sendersysid
;



select regexp_substr(wonum, '^\w*'), count(*)
from invreserve
where REQUESTEDDATE >= sysdate - 90
group by regexp_substr(wonum, '^\w*')
order by count(*) desc;


/********************************************************************
* Find duplicate inventory reservations
*  - Simplified script for Pick List and escalation to flag duplicates
*********************************************************************/

select *
from workorder
where wonum in
    (SELECT invreserve.wonum
    FROM maximo.invreserve
    WHERE invreserve.location = 'CENTRAL'
        AND (SELECT COUNT(*) cnt
                FROM maximo.invreserve dupreserv
                WHERE dupreserv.wonum = invreserve.wonum
                    AND dupreserv.itemnum = invreserve.itemnum
                    AND dupreserv.location = 'CENTRAL'
                GROUP BY dupreserv.wonum, dupreserv.mrnum, dupreserv.itemnum
                HAVING COUNT(*) > 1) 
            !=
            (SELECT COUNT(*) FROM maximo.wpmaterial WHERE wpmaterial.itemnum = invreserve.itemnum AND wpmaterial.wonum = invreserve.wonum))

;


/********************************************************************
* Find Workorders which can be used to generate duplicates
* - Approved WO with approved Tasks
* - Tasks have inventory materials planned
*********************************************************************/

select workorder.wonum, 
    (select count(*)
        from wpmaterial
        where linetype = 'ITEM'
            and location = 'CENTRAL'
            and DIRECTREQ = 0
            and (wpmaterial.wonum = workorder.wonum)) WO_MATERIAL,
    (select count(*)
        from invreserve
        where invreserve.wonum = workorder.wonum) WORKORDER_INVRESERVES,
        
    wotask.wonum task_wonum,
    (select count(*)
        from wpmaterial
        where linetype = 'ITEM'
            and location = 'CENTRAL'
            and DIRECTREQ = 0
            and (wpmaterial.wonum = wotask.wonum)) WOTASK_MATERIAL,
    (select count(*)
        from invreserve
        where invreserve.wonum = wotask.wonum) WOTASK_INVRESERVES
from workorder
    join woactivity wotask on wotask.parent = workorder.wonum
where workorder.status = 'APPR' 
    and wotask.status = 'APPR'
    and exists (select 1
                from wpmaterial
                where linetype = 'ITEM'
                    and location = 'CENTRAL'
                    and DIRECTREQ = 0
                    and wpmaterial.wonum = wotask.wonum)
    and (
--    ((select count(*)
--        from wpmaterial
--        where linetype = 'ITEM'
--            and location = 'CENTRAL'
--            and DIRECTREQ = 0
--            and (wpmaterial.wonum = wotask.wonum)) 
--        =
--    (select count(*)
--        from invreserve
--        where invreserve.wonum = wotask.wonum))
--        
--        or 
        
        workorder.wonum in ('CENT.1095377')
    )
        
order by workorder.wonum, wotask.wonum asc
;

