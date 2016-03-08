
/*******************************************************************************
*  Count of attribute values by classification and assetattrid
*******************************************************************************/

select Classstructure.Classstructureid, case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid HIERARCHYPATH,
  Cispec.Assetattrid, count(Cispec.alnvalue)
from Classstructure
  left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
  left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
  left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
  left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid
  join Ci on Ci.Classstructureid = Classstructure.Classstructureid
  join Cispec on Cispec.Cinum = Ci.Cinum
group by Classstructure.Classstructureid, case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid, Cispec.Assetattrid
order by classstructureid;



/*******************************************************************************
*  Full list of assets with attr, alnvalue, and hierarchypath
*******************************************************************************/

select Ci.Ciname, Cispec.Assetattrid, cispec.Alnvalue,
  case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid HIERARCHYPATH
from Classstructure
  left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
  left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
  left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
  left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid
  join Ci on Ci.Classstructureid = Classstructure.Classstructureid
  join Cispec on Cispec.Cinum = Ci.Cinum
  order by Ci.Ciname, Cispec.Assetattrid;
