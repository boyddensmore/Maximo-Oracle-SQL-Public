
/*******************************************************************************
*  Simplified, VMs with hosted location
*******************************************************************************/

select distinct HOST_ASSET.LOCATION FULL_HOST_LOCATION, 
  case when instr(HOST_ASSET.LOCATION, '-') != 0 then substr(HOST_ASSET.LOCATION, 0, instr(HOST_ASSET.LOCATION, '-')-1) else HOST_ASSET.LOCATION end HOST_BUILDING,
  VM.CINAME VM_CINAME
from ci VM
  join CIRELATION VM_CLUST_REL on VM.cinum = VM_CLUST_REL.SOURCECI
  join ci CLUST on CLUST.cinum = VM_CLUST_REL.TARGETCI
  left join CIRELATION CLUST_HOST_REL on CLUST_HOST_REL.SOURCECI = CLUST.CINUM
  join ci HOST on HOST.CINUM = CLUST_HOST_REL.TARGETCI
  left join asset HOST_ASSET on HOST_ASSET.ASSETNUM = HOST.ASSETNUM
where VM.CLASSSTRUCTUREID = 'CCI00112'
  and CLUST.CLASSSTRUCTUREID = '1185'
  and HOST.CLASSSTRUCTUREID = '1070'
  and VM.STATUS != 'DECOMMISSIONED'
  and CLUST.STATUS != 'DECOMMISSIONED'
  and HOST.STATUS != 'DECOMMISSIONED'
group by HOST_ASSET.LOCATION, VM.CINAME
order by HOST_ASSET.LOCATION, VM.CINAME;


/*******************************************************************************
*  Detailed, VM, Cluster, Host
*******************************************************************************/

select distinct HOST_ASSET.LOCATION FULL_HOST_LOCATION, 
  case when instr(HOST_ASSET.LOCATION, '-') != 0 then substr(HOST_ASSET.LOCATION, 0, instr(HOST_ASSET.LOCATION, '-')-1) else HOST_ASSET.LOCATION end HOST_BUILDING,
  HOST.CINAME HOST_CINAME, CLUST.CINAME CLUST_CINAME, VM.CINAME VM_CINAME
from ci VM
  join CIRELATION VM_CLUST_REL on VM.cinum = VM_CLUST_REL.SOURCECI
  join ci CLUST on CLUST.cinum = VM_CLUST_REL.TARGETCI
  left join CIRELATION CLUST_HOST_REL on CLUST_HOST_REL.SOURCECI = CLUST.CINUM
  join ci HOST on HOST.CINUM = CLUST_HOST_REL.TARGETCI
  left join asset HOST_ASSET on HOST_ASSET.ASSETNUM = HOST.ASSETNUM
where VM.CLASSSTRUCTUREID = 'CCI00112'
  and CLUST.CLASSSTRUCTUREID = '1185'
  and HOST.CLASSSTRUCTUREID = '1070'
  and VM.STATUS != 'DECOMMISSIONED'
  and CLUST.STATUS != 'DECOMMISSIONED'
  and HOST.STATUS != 'DECOMMISSIONED'
group by HOST_ASSET.LOCATION, HOST.CINAME, CLUST.CINAME, VM.CINAME
order by HOST_ASSET.LOCATION, HOST.CINAME, CLUST.CINAME, VM.CINAME;