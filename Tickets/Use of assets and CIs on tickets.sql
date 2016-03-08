
/*******************************************************************************
*  Count of tickets for each asset
*******************************************************************************/

select sr.ASSETNUM, asset.ASSETTAG, count(*)
from sr
  left join asset on sr.ASSETNUM = asset.ASSETNUM
group by sr.ASSETNUM, asset.ASSETTAG
order by count(*) desc;




/*******************************************************************************
*  Count of tickets for each asset
*******************************************************************************/

