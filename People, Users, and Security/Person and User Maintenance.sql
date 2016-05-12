
/*******************************************************************************
*  List of people who have been PEND_DEACTIV for 30 days or more and have not
*  left PEND_DEACTIV in the past 30 days.
*******************************************************************************/

select personid
from PERSON
where personid in 
  (select upper(EXIFACE_WDAYPERSON.personid)
  from EXIFACE_WDAYPERSON
  where EXIFACE_WDAYPERSON.STATUS = 'PEND_DEACTIV'
    and EXIFACE_WDAYPERSON.EX_TRANSDATETIME > sysdate - 31
    and EXIFACE_WDAYPERSON.EX_TRANSDATETIME < sysdate - 30)
  and personid not in
  (select upper(EXIFACE_WDAYPERSON.personid)
  from EXIFACE_WDAYPERSON
  where EXIFACE_WDAYPERSON.STATUS != 'PEND_DEACTIV'
    and EXIFACE_WDAYPERSON.EX_TRANSDATETIME > sysdate - 31)
  and PERSON.STATUS = 'PEND_DEACTIV';


/*******************************************************************************
*  PEND_DEACTIV people with no asset, ticket, commtemplate ownership, is not a 
*  member of a person group, and is not a supervisor
*  Use with MXLoader to make these people INACTIVE.
*******************************************************************************/

select ' ,''' || PERSON.personid || '''', person.status
from PERSON
where PERSON.personid in 
    (select upper(EXIFACE_WDAYPERSON.personid)
    from EXIFACE_WDAYPERSON
    where EXIFACE_WDAYPERSON.STATUS = 'PEND_DEACTIV'
      and EXIFACE_WDAYPERSON.EX_TRANSDATETIME > sysdate - 31
      and EXIFACE_WDAYPERSON.EX_TRANSDATETIME < sysdate - 30)
  and PERSON.personid not in
    (select upper(EXIFACE_WDAYPERSON.personid)
    from EXIFACE_WDAYPERSON
    where EXIFACE_WDAYPERSON.STATUS != 'PEND_DEACTIV'
      and EXIFACE_WDAYPERSON.EX_TRANSDATETIME > sysdate - 31)
  and PERSON.PERSONID not in
    (select PERSON.personid from PERSON join ASSETUSERCUST on PERSON.PERSONID = ASSETUSERCUST.PERSONID join ASSET on ASSETUSERCUST.ASSETNUM = ASSET.ASSETNUM)
  and PERSON.PERSONID not in
    (select distinct person.personid from PERSON join TICKET on PERSON.PERSONID = TICKET.OWNER)
  and PERSON.PERSONID not in
    (select RESPPARTY from PERSONGROUPTEAM)
  and PERSON.PERSONID not in
    (select distinct PERSON.SUPERVISOR from person where PERSON.SUPERVISOR is not null)
  and PERSON.PERSONID not in
    (select distinct CREATEBY from MAXIMO.COMMTEMPLATE)
  and PERSON.STATUS = 'PEND_DEACTIV';


/*******************************************************************************
*  Invalidate email addresses of people who are not members of a person group.
*******************************************************************************/

update EMAIL
set EMAILADDRESS = 'MITQA_' || EMAILADDRESS
where PERSONID not in (select distinct respparty from PERSONGROUPTEAM);

/*******************************************************************************
*  Count of person deactivations by day
*******************************************************************************/

select to_date(to_char(changedate, 'mm-dd-yy'), 'mm-dd-yy') DEACTIV_DATE, count(*)
from personstatus
where status = 'PEND_DEACTIV'
group by to_date(to_char(changedate, 'mm-dd-yy'), 'mm-dd-yy')
order by to_date(to_char(changedate, 'mm-dd-yy'), 'mm-dd-yy') desc;

/*******************************************************************************
*  Count of user deactivations by day
*******************************************************************************/

select to_date(to_char(changedate, 'mm-dd-yy'), 'mm-dd-yy'), count(*)
from MAXUSERSTATUS
where status = 'INACTIVE'
group by to_date(to_char(changedate, 'mm-dd-yy'), 'mm-dd-yy')
order by to_date(to_char(changedate, 'mm-dd-yy'), 'mm-dd-yy') desc;



/*******************************************************************************
*  Active users with inactive persons
*******************************************************************************/

select ',' || maxuser.userid, maxuser.personid, maxuser.status, maxuser.type
from maxuser
where status = 'ACTIVE'
  and personid in
  (select person.personid
  from person 
    join personstatus on personstatus.PERSONID = person.PERSONID
  where person.status != 'ACTIVE'
    and personstatus.STATUS != 'ACTIVE'
    and personstatus.changedate <= sysdate - 10);


/*******************************************************************************
*  Inactive users with active persons
*******************************************************************************/

select ',' || MAXUSER.userid, MAXUSER.personid, MAXUSER.status U_STATUS, MAXUSER.type
from MAXUSER
where MAXUSER.status != 'ACTIVE'
  and personid in
  (select person.personid
  from person 
    join personstatus on personstatus.PERSONID = person.PERSONID
  where person.status = 'ACTIVE');



/*******************************************************************************
*  People with invalid COMPANY
*******************************************************************************/

select distinct person.personid, person.status, person.company, person.EX_BUSINESSUNIT, person.DEPARTMENT
from person
  join ASSETLOCUSERCUST on person.PERSONID = ASSETLOCUSERCUST.PERSONID
where person.company not in ('[[COMPANY]]')
order by person.company;


select distinct department, company, EX_BUSINESSUNIT, count(personid)
from person
where department in
  (select distinct department
  from person 
  where personid in 
    (select distinct person.personid
    from person
      join assetlocusercust on person.personid = assetlocusercust.personid
    where person.company not in ('[[COMPANY]]')))
group by department, company, EX_BUSINESSUNIT
order by department, company, EX_BUSINESSUNIT;


select distinct company, department from person where department in ('33240');


/*******************************************************************************
*  Count of different department description for each dept ID.
*  Each should have only 1.
*******************************************************************************/

select department, count(*)
from 
  (select distinct department, deptdesc
  from person
  order by department)
group by department
order by count(*) desc;

select personid, department, deptdesc
from person
where department is null 
  and deptdesc is not null;

/*******************************************************************************
*  Testing: People with null Dept IDs
*******************************************************************************/

select *
from person
where DEPARTMENT is null
and status = 'ACTIVE';


/*******************************************************************************
*  Testing: Show all rows in interface table (data table)
*******************************************************************************/

select *
from Exiface_Wdayperson
order by transid desc;

select *
from Exiface_Wdayperson
where status like ' %'
order by transid desc;


/*******************************************************************************
*  Re-populate the MXIN_INTER_TRANS table based on the EXIFACE_WDAYPERSON table
*******************************************************************************/  
insert into MXIN_INTER_TRANS (transid)
select transid from EXIFACE_WDAYPERSON;

update mxin_inter_trans
set IFACENAME = 'EX_WDAYPERSON', ACTION = 'Change', EXTSYSNAME = 'EX_IFACETAB_IFACE';


/*******************************************************************************
*  Populate PERSON.LASTEVALDATE with latest EX_TRANSDATETIME from iface table
*******************************************************************************/

update person
set (LASTEVALDATE) = (select max(EXIFACE_WDAYPERSON.EX_TRANSDATETIME) from EXIFACE_WDAYPERSON where person.personid = upper(EXIFACE_WDAYPERSON.PERSONID));

-- Testing, check results of above
select personid, (select max(EXIFACE_WDAYPERSON.EX_TRANSDATETIME) from EXIFACE_WDAYPERSON where upper(EXIFACE_WDAYPERSON.PERSONID) = person.personid) from person;
select person.personid, person.LASTEVALDATE from person where LASTEVALDATE is not null;
select person.personid, person.LASTEVALDATE from person where LASTEVALDATE is null;

