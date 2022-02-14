/*******************************************************************************
* Find Job Plans with inactive assets
*  - This report returns all inactive assets listed on active Job Plans
*  - If changes are made to a Job Plan which has an inactive asset,
*    integration errors are caused when the record integrates:
*     e.g. BMXAA0090E - Asset 44075 is not a valid asset, or its 
*          status is not an operating status.
*
*  - The results of this query were sent to CMMS on Sept 8, 2017 for cleanup
*******************************************************************************/

select jobplan.jpnum KEY, 'JOBPLAN' TABLENAME, 'Active Job Plan uses inactive Work Asset: ' || asset.assetnum DESCRIPTION, 'FIX' XLEVEL, 'DATA' SRC
from maximo.jobplan
    left join maximo.JPASSETSPLINK on JPASSETSPLINK.jpnum = jobplan.jpnum
    left join maximo.asset on asset.assetnum = JPASSETSPLINK.assetnum
where jobplan.status in ('ACTIVE', 'PNDREV')
    and asset.status = 'DECOMMISSIONED'
;