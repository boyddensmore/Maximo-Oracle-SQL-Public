select * from locations;
select location, status, changedate, Changeby from Locstatus 
where changedate >= sysdate - 2;


/*******************************************************************************
*  Location classifications
*******************************************************************************/

select Classstructure.Classificationid, Classstructure.Classstructureid
from Classstructure
  join Classusewith on Classusewith.Classstructureid = Classstructure.Classstructureid
where Classusewith.Objectname = 'LOCATIONS';

/*******************************************************************************
*  Count of locations by classification
*******************************************************************************/

Select Locations.classstructureid, Classstructure.Classificationid, count(*)
from Locations
  left join Classstructure on Classstructure.Classstructureid = Locations.Classstructureid
group by Locations.Classstructureid, Classstructure.Classificationid
order by Locations.Classstructureid;


/*******************************************************************************
* Count of assets and people by location
*******************************************************************************/

select 
  case when Loc_L7.location is not null then Loc_L7.location || ' / ' else '' end ||
  case when Loc_L6.location is not null then Loc_L6.location || ' / ' else '' end ||
  case when Loc_L5.location is not null then Loc_L5.location || ' / ' else '' end ||
  case when Loc_L4.location is not null then Loc_L4.location || ' / ' else '' end ||
  case when Loc_L3.location is not null then Loc_L3.location || ' / ' else '' end ||
  case when Loc_L2.location is not null then Loc_L2.location || ' / ' else '' end ||
  case when Loc_L1.location is not null then Loc_L1.location || ' / ' else '' end ||
  locations.location LOCATIONPATH,
  Classstructure.Classificationid/*,
  (select count(*) from asset where asset.location = locations.location) ASSET_COUNT,
  (select count(*) from person where person.location = locations.location) PERSON_COUNT*/
from locations
  left join (select location, parent from lochierarchy) LH_L1 on Lh_L1.Location = Locations.Location
  left join locations Loc_L1 on loc_l1.location = Lh_L1.Parent
  left join (select location, parent from lochierarchy) LH_L2 on Lh_L2.Location = Loc_l1.Location
  left join locations Loc_L2 on loc_l2.location = Lh_L2.Parent
  left join (select location, parent from lochierarchy) LH_L3 on Lh_L3.Location = Loc_l2.Location
  left join locations Loc_L3 on loc_l3.location = Lh_L3.Parent
  left join (select location, parent from lochierarchy) LH_L4 on Lh_L4.Location = Loc_l3.Location
  left join locations Loc_L4 on loc_l4.location = Lh_L4.Parent
  left join (select location, parent from lochierarchy) LH_L5 on Lh_L5.Location = Loc_l4.Location
  left join locations Loc_L5 on loc_l5.location = Lh_L5.Parent
  left join (select location, parent from lochierarchy) LH_L6 on Lh_L6.Location = Loc_l5.Location
  left join locations Loc_L6 on loc_l6.location = Lh_L6.Parent
  left join (select location, parent from lochierarchy) LH_L7 on Lh_L7.Location = Loc_l6.Location
  left join locations Loc_L7 on loc_l7.location = Lh_L7.Parent
  left join Classstructure on Classstructure.classstructureid = Locations.Classstructureid
order by locations.location;