
/*******************************************************************************
*  Count of attribute values by classification and assetattrid
*******************************************************************************/

select Classstructure.Classstructureid, case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid HIERARCHYPATH,
  Assetspec.Assetattrid, count(assetspec.alnvalue)
from Classstructure
  left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
  left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
  left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
  left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid
  join asset on Asset.Classstructureid = Classstructure.Classstructureid
  join Assetspec on Assetspec.Assetnum = asset.assetnum
group by Classstructure.Classstructureid, case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid, Assetspec.Assetattrid
order by classstructureid;



/*******************************************************************************
*  Full list of assets with attr, alnvalue, and hierarchypath
*******************************************************************************/

select Asset.Assetnum, Assetspec.Assetattrid, Assetspec.Alnvalue,
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
  join asset on Asset.Classstructureid = Classstructure.Classstructureid
  join Assetspec on Assetspec.Assetnum = asset.assetnum
where Assetspec.Assetattrid = 'FUNCTION'
  and Assetspec.Alnvalue is not null
order by asset.assetnum, Assetspec.Assetattrid;



select Assetattrid, Alnvalue
from Assetspec
where Assetattrid = 'FUNCTION'
  and alnvalue is not null;