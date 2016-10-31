/*******************************************************************************
*  Collection details, including all asset, CI, and location members
*******************************************************************************/

select COLLECTION.COLLECTIONNUM, COLLECTION.DESCRIPTION, COLLECTION.ISACTIVE,
  COLLECTDETAILS.CINUM, CI.CINAME, CI.STATUS CI_STATUS,
  COLLECTDETAILS.ASSETNUM, ASSET.ASSETTAG, ASSET.STATUS ASSET_STATUS,
  COLLECTDETAILS.LOCATION, LOCATIONS.DESCRIPTION
from collection
  left join COLLECTDETAILS on COLLECTION.COLLECTIONNUM = COLLECTDETAILS.COLLECTIONNUM
  left join asset on COLLECTDETAILS.ASSETNUM = ASSET.ASSETNUM
  left join ci on COLLECTDETAILS.CINUM = CI.CINUM
  left join LOCATIONS on LOCATIONS.LOCATION = COLLECTDETAILS.LOCATION
;