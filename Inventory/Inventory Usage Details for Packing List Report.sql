/*******************************************************************************
* Statement name and description
*  - 
*  - 
*  - Do we care about unit cost?  Issue unit?  Would we be better off with line cost?
*  - Cost is calculated from AVERAGE cost.  This may change, and we may not want to 
*    do this ourselves.  The old report pulled from MATUSETRANS, where Maximo had 
*    already calculated the costs because the issue was complete.
*  - 
*******************************************************************************/

SELECT
    invuse.invusenum batchnum,
    invuse.usetype,
    invuseline.invuselinenum,
    CASE
        WHEN invuseline.refwo IS NOT NULL THEN 'WO'
        WHEN mr.mrnum IS NOT NULL THEN 'MR' 
    END category,
    nvl(workorder.parent, workorder.wonum) parentwo,
    invuseline.refwo wonum,
    CASE
        WHEN workorder.istask = 1 THEN invuseline.refwo
    END taskwonum,
    CASE
        WHEN workorder.istask = 1 THEN workorder.description
    END taskwodesc,
    CASE
        WHEN workorder.wonum IS NOT NULL THEN nvl((SELECT wo.description FROM workorder wo WHERE wo.wonum = workorder.parent), workorder.description)
    END wodesc,
    workorder.istask,
    workorder.taskid,
    invuseline.mrnum,
    mr.description mrdesc,
    CASE
        WHEN workorder.wonum IS NOT NULL THEN workorder.location
        WHEN mr.mrnum IS NOT NULL THEN mr.location
    END location,
    wpmaterial.wpm2 WODP,
    invusestagedby.changeby stagedby,
    invusestagedby.changedate stageddate,
    invuseline.itemnum,
    invuseline.description itemdesc,
    CASE
        WHEN wpmaterial.itemqty IS NOT NULL THEN wpmaterial.itemqty
        WHEN mrline.qty IS NOT NULL THEN mrline.qty
    END qtyrequested,
    invuseline.quantity qty,
    invcost.avgcost unitcost,
    invuseline.linecost,
    item.issueunit,
    invuseline.requestnum,
    invuseline.issueto requestby
FROM invuse
    LEFT JOIN invusestatus invusestagedby ON (invusestagedby.invusenum = invuse.invusenum
                                            AND invusestagedby.status IN (SELECT value 
                                                                        FROM synonymdomain 
                                                                        WHERE domainid = 'INVUSESTATUS' AND maxvalue = 'STAGED'))
    LEFT JOIN invuseline ON invuse.invusenum = invuseline.invusenum
    LEFT JOIN item ON item.itemnum = invuseline.itemnum
    LEFT JOIN workorder ON workorder.wonum = invuseline.refwo
    LEFT JOIN mr ON (mr.mrnum = invuseline.mrnum)
    LEFT JOIN mrline ON (mrline.mrnum = invuseline.mrnum AND mrline.mrlinenum = invuseline.mrlinenum)
    LEFT JOIN invcost ON (invcost.itemnum = invuseline.itemnum AND invcost.location = invuseline.fromstoreloc)
    LEFT JOIN wpmaterial ON (wpmaterial.wonum = invuseline.refwo AND wpmaterial.itemnum = invuseline.itemnum)
-- where " + params["where"]
ORDER BY invuse.invusenum, invuseline.refwo, invuseline.mrnum, invuseline.invuselinenum
;
