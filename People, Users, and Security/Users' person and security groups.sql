/*******************************************************************************
*  BD - To use, replace USERID on line 5 with the user in question.  Run this SQL as
*  a script (F5 in SQL Developer) and check the script output for all details.
*******************************************************************************/


define USERID = "'[[USERNAME]]'";

--Find all security groups a user is in
select Groupuser.Userid, Groupuser.Groupname
from maximo.groupuser
where Groupuser.Userid = &USERID;

--Find all person groups a user is in
select Persongroupteam.Respparty, Persongroupteam.Persongroup, ',=' || Persongroupteam.Persongroup
from maximo.Persongroupteam
where respparty = &USERID;


--Find all people who are members of non-default security groups
--select DISTINCT groupuser.Userid, Person.Firstname, Person.Lastname, Email.Emailaddress
--from groupuser, Person, Email
--where Groupuser.Userid = Person.Personid
--and Email.Personid = Person.Personid
--and Email.Isprimary = 1
--and groupname not in ('MAXDEFLTREG', 'MAXEVERYONE')
--order by userid;


-- List all Security Groups and membership
select Groupuser.Groupname, Groupuser.Userid,
    person.firstname, person.lastname, person.displayname,
    maxuser.status userstatus, person.status personstatus
from maximo.groupuser
    left join maxuser on maxuser.userid = groupuser.userid
    left join person on person.personid = maxuser.personid
order by groupuser.groupname, groupuser.userid
;