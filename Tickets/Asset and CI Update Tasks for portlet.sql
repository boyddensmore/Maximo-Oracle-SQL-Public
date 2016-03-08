select WOACTIVITY.WONUM, woactivity.owner, woactivity.ownergroup, woactivity.description, woactivity.assetnum, woactivity.cinum, woactivity.reportdate
from woactivity
where status not in ('COMP', 'CAN', 'CLOSE', 'FAIL') 
  and (historyflag = 0 and siteid = 'IT-IS') 
  and ( contains(description,'  $Update   &   $Asset   &   $/   &   $CI  ') > 0 ) 
  and ownergroup in (select persongroup from persongroupteam where respparty = 'BDENSMOR'  ) 
  and owner is null;
  
  
select WOACTIVITY.WONUM, woactivity.owner, woactivity.ownergroup, woactivity.description, woactivity.assetnum, woactivity.cinum, woactivity.reportdate
from woactivity
where status not in ('COMP', 'CAN', 'CLOSE', 'FAIL') 
  and (historyflag = 0 
  and siteid = 'IT-IS') 
  and ( contains(description,'  $Update   &   $Asset   &   $/   &   $CI  ') > 0 ) 
  and owner = 'BDENSMOR';

  
select woactivity.owner, woactivity.ownergroup, woactivity.description, woactivity.assetnum, woactivity.cinum, woactivity.reportdate
from woactivity
where woactivity.status = 'WAPPR'
and ( contains(description,'  $Update   &   $Asset   &   $/   &   $CI  ') > 0 )
and 
  (ownergroup in (select persongroup from persongroupteam where respparty = :USER )
  OR
  owner = :USER);