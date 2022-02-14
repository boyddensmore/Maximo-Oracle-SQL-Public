/*******************************************************************************
* Checking LocHierarchy consistency
*******************************************************************************/

-- Location has children in system but children flag is 0
select 
    *
--    count(*)
from maximo.lochierarchy
where children = 0
    and exists (select 1 from maximo.lochierarchy loc_children where loc_children.parent = lochierarchy.location and loc_children.systemid = lochierarchy.systemid);


-- Location has no children in system but children flag is 1
select 
    count(*)
from maximo.lochierarchy
where children = 1
    and not exists (select 1 from maximo.lochierarchy loc_children where loc_children.parent = lochierarchy.location and loc_children.systemid = lochierarchy.systemid);


-- Find locations in lochierarchy where parent doesn't exist
----------------------------
-- !!No longer an issue!! --
----------------------------
--select *
--from maximo.lochierarchy
--where lochierarchy.parent is not null
--    and not exists (select 1 from maximo.lochierarchy loc_parent where loc_parent.location = lochierarchy.parent);
--
--    -- Set Parent to null in lochierarchy where parent doesn't exist
--    update maximo.lochierarchy
--    set parent = null
--    where lochierarchy.parent is not null
--        and not exists (select 1 from maximo.lochierarchy loc_parent where loc_parent.location = lochierarchy.parent);
--    commit;


--Find locations which don't have a location record.
-- Incidentally, all 90 of these records had spaces on the end of them, didn't exist as locations, and were not Parents for any locations.  
--Deleted them
select '4. LOCATION_DOESNT_EXIST' as ISSTYPE, count(*) RESULT
from maximo.lochierarchy
where not exists (select 1 from maximo.locations where locations.location = lochierarchy.location)
    and location != trim(location)
    and exists (select 1 from maximo.lochierarchy parent_loc where parent_loc.parent = lochierarchy.location);

    -- Delete
    delete from maximo.lochierarchy
    where not exists (select 1 from maximo.locations where locations.location = lochierarchy.location)
        and location != trim(location)
        and exists (select 1 from maximo.lochierarchy parent_loc where parent_loc.parent = lochierarchy.location);
    commit;



--
--  Checking for orphaned loc hierarchy.
--

select '5. SYSTEM_MISMATCH' as "Issue Type",
    node.parent "Parent",
    (select status from locations where locations.location = node.parent) "Parent Status",
    node.location "Location",
    (select status from locations where locations.location = node.location) "Location Status",
    listagg(parent.systemid, ', ') within group (order by node.location, node.parent, node.systemid) "Parent Systems",
    node.systemid "Location System",
    (select listagg(systemid, ', ') within group (order by systemid)
        from lochierarchy
        where lochierarchy.parent = node.location
        group by lochierarchy.parent) "Children Systems"
from lochierarchy node
    join lochierarchy parent on parent.location = node.parent
where node.parent is not null
    and not exists (select 1 from lochierarchy where location = node.parent and systemid = node.systemid)
group by node.location, node.parent, node.systemid
;


select location, parent, systemid
from lochierarchy node
where node.parent is not null
    and not exists (select 1 from lochierarchy parent where parent.location = node.parent and parent.systemid = node.systemid)
    and (select count(distinct systemid) from lochierarchy where lochierarchy.location = node.location group by location) = 1
    and node.parent not in (select location
                            from lochierarchy node
                            where node.parent is not null
                                and not exists (select 1 from lochierarchy parent where parent.location = node.parent and parent.systemid = node.systemid)
                                and (select count(distinct systemid) from lochierarchy where lochierarchy.location = node.location group by location) = 1)
;
    





/*******************************************************************************
* Update and Delete Statements
*******************************************************************************/


-- 1. Set children flag to 1 where location has children
update maximo.lochierarchy
set children = 1
where children = 0
    and exists (select 1 from maximo.lochierarchy loc_children where loc_children.parent = lochierarchy.location and loc_children.systemid = lochierarchy.systemid);
commit;

-- 2. Set children flag to 0 where location has no children
update maximo.lochierarchy
set children = 0
where children = 1
    and not exists (select 1 from maximo.lochierarchy loc_children where loc_children.parent = lochierarchy.location and loc_children.systemid = lochierarchy.systemid);
commit;

-- 5. Set child system to be same as parent
-----------------------------
-- RUN UNTIL NO ROWS UPDATED
-----------------------------
update lochierarchy node
set systemid = (select systemid from lochierarchy parent where parent.location = node.parent)
where node.parent is not null
    and not exists (select 1 from lochierarchy parent where parent.location = node.parent and parent.systemid = node.systemid)
    and (select count(distinct systemid) from lochierarchy where lochierarchy.location = node.location group by location) = 1
    -- Where location is not a child of an affected location
    and node.parent not in (select location
                            from lochierarchy node
                            where node.parent is not null
                                and not exists (select 1 from lochierarchy parent where parent.location = node.parent and parent.systemid = node.systemid)
                                and (select count(distinct systemid) from lochierarchy where lochierarchy.location = node.location group by location) = 1)
;
