
/*******************************************************************************
* Associated users and custodians for an asset, including LEGACY_BU_OWNER
*******************************************************************************/

select Assetusercust.Assetnum, Asset.Description, Asset.Assettag, 
        Assetusercust.Personid, Assetusercust.Isuser, Assetusercust.Iscustodian, 
        Assetusercust.Isprimary, Person.Department, Person.Deptdesc, Legacy_Bu_Owner.Alnvalue LEGACY_BU_OWNER
from asset
  left join Assetusercust on Asset.Assetnum = assetusercust.assetnum
  left join person on Assetusercust.Personid = Person.Personid
  left join 
    (select ASSET.ASSETNUM, Assetspec.Alnvalue
    from asset
        join assetspec on Assetspec.Assetnum = Asset.Assetnum
    where Asset.classstructureid in ('1238', '1243')
    and Asset.Status = 'DEPLOYED'
    and Assetspec.Assetattrid = 'LEGACY_BU_OWNER') LEGACY_BU_OWNER on Asset.Assetnum = Legacy_Bu_Owner.Assetnum
where Asset.Status = 'DEPLOYED'
and Asset.classstructureid in ('1238', '1243')
--and (Assetusercust.Isuser = 1 or Assetusercust.Iscustodian = 1 or Assetusercust.Isprimary = 1)
--and Assetusercust.Personid is null
order by asset.assetnum;


/*******************************************************************************
*  Assets with specs
*******************************************************************************/

select count(Asset.Assetnum)
from asset
    left join assetspec on Assetspec.Assetnum = Asset.Assetnum
where Asset.classstructureid in ('1238', '1243')
and Asset.Status = 'DEPLOYED'
and Assetspec.Assetattrid = 'LEGACY_BU_OWNER';

/*******************************************************************************
*  Assets with no user or custodian
*******************************************************************************/

select asset.assetnum, asset.description, asset.classstructureid,
        Asset.Ex_Other, Classstructure.Description CLASS_DESCRIPTION, 
        asset.assettag, asset.serialnum
from asset, Classstructure
where Asset.Classstructureid = Classstructure.Classstructureid
and Asset.Assetnum not in
  (select Assetusercust.Assetnum
  from Assetusercust
  where (Assetusercust.Isprimary = 1 or Assetusercust.Iscustodian = 1))
and Asset.status = 'DEPLOYED'
-- Only show workstations
and Asset.classstructureid in ('1238', '1243');


/*******************************************************************************
*  Assets associated with deactivated people
*******************************************************************************/

select asset.assetnum, asset.description, asset.classstructureid, 
        Classstructure.Description CLASS_DESCRIPTION, asset.assettag, 
        asset.serialnum, Assetusercust.Personid, Assetusercust.Isprimary, 
        Assetusercust.Iscustodian, Assetusercust.Isuser
from asset
  left join Classstructure on Asset.Classstructureid = Classstructure.Classstructureid
  left join assetusercust on Asset.Assetnum = Assetusercust.Assetnum
where Asset.Assetnum in
  (select Assetnum
  from Assetusercust
  where personid in
    (select person.personid
      from person
      where ( contains(person.displayname,' %xxx% ') > 0 )
      and person.personid not in ('DESKSIDE')))
and Asset.status = 'DEPLOYED'
-- Only show workstations
and Asset.classstructureid in ('1238', '1243')
order by assetnum;


/*******************************************************************************
*  Assets associated with people with no Department
*******************************************************************************/
select asset.assetnum, asset.description, asset.classstructureid, 
        Classstructure.Description CLASS_DESCRIPTION, asset.assettag, 
        asset.serialnum, Assetusercust.Personid, Assetusercust.Isprimary, 
        Assetusercust.Iscustodian, Assetusercust.Isuser
from asset, Classstructure, assetusercust
where Asset.Classstructureid = Classstructure.Classstructureid
and Asset.Assetnum = Assetusercust.Assetnum(+)
and Asset.Assetnum in
  (select Assetnum
  from Assetusercust
  where personid in
    (select person.personid
      from person
      where Person.Department is null
      and person.personid not in ('DESKSIDE')))
and Asset.status = 'DEPLOYED'
-- Only show workstations
and Asset.classstructureid in ('1238', '1243')
and (Assetusercust.Isprimary = 1 or Assetusercust.Iscustodian = 1)
order by assetnum;


/*******************************************************************************
*  Users with NULL dept.
*******************************************************************************/

select 
count(person.personid)
-- Person.personid, Person.displayname, Person.status, Person.department, 
--    Person.deptdesc, Person.title, Person.statusdate
from person, maxuser
where Maxuser.Personid = Person.Personid

and Maxuser.Status = 'ACTIVE'
-- Exclude records disabled in AD, which are prefixed with 'xxx'.
and ( not contains(displayname,' %xxx% ') > 0 );


/*******************************************************************************
*  Count of users by dept code (Excluding deactivated people)
*******************************************************************************/

select department, count(personid)
from person
where status = 'ACTIVE'
and ( not contains(displayname,' %xxx% ') > 0 )
group by department
order by count(personid) desc;


/*******************************************************************************
*  Users deactivated in AD
*******************************************************************************/

select person.personid
from person, assetusercust
where Person.Personid = Assetusercust.Personid(+)
and person.status = 'ACTIVE'
and ( contains(person.displayname,' %xxx% ') > 0 );
