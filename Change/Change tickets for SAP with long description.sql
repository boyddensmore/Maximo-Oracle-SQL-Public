-- REGEX to remove all HTML tags.
-- REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' ') LONG_DESCRIPTION

select wochange.wonum, Wochange.Description, Wochange.Owner, Wochange.Ownergroup, 
  wochange.status, WOCHANGE.PMCHGTYPE, WOCHANGE.PMCHGCAT,
  REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' ') LONG_DESCRIPTION, 
  Longdescription.Ldtext LONG_DESCRIPTION_HTML, 
  Wochange.Schedstart, Wochange.Schedfinish
from wochange
  join Longdescription on LONGDESCRIPTION.LDKEY = Wochange.Workorderid
where Longdescription.Ldownertable = 'WORKORDER'
  and Longdescription.Ldownercol = 'DESCRIPTION'
  and WOCHANGE.SCHEDSTART >= sysdate - 20;
