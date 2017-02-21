/*******************************************************************************
*  BD - To use, replace USERID on line 6 with the user in question.  Run this SQL as
*  a script (F5 in SQL Developer) and check the script output for all details.
*******************************************************************************/

select userid, displayname
from maxuser
  left join PERSON on person.personid = MAXUSER.PERSONID
where userid like 'U%%';
define USERID = "'[[USERNAME]]'";

--Find all security groups a user is in
select Groupuser.Userid, Groupuser.Groupname
from groupuser
where Groupuser.Userid = &USERID;

-- What groups grant access to template
select GROUPNAME, DESCRIPTION, SCTEMPLATEID
from MAXGROUP
where SCTEMPLATEID = 3;

--Find all person groups a user is in
select Persongroupteam.Respparty, Persongroupteam.Persongroup, ',=' || Persongroupteam.Persongroup
from Persongroupteam
where respparty = &USERID;


--Find all people who are members of non-default security groups
--select DISTINCT groupuser.Userid, Person.Firstname, Person.Lastname, Email.Emailaddress
--from groupuser, Person, Email
--where Groupuser.Userid = Person.Personid
--and Email.Personid = Person.Personid
--and Email.Isprimary = 1
--and groupname not in ('MAXDEFLTREG', 'MAXEVERYONE')
--order by userid;



--Find all security groups a user is in
select Groupuser.Userid, Groupuser.Groupname
from groupuser
where Groupuser.Userid in ('[[USERNAME]]');

select Persongroupteam.Respparty, Persongroupteam.Persongroup, ',=' || Persongroupteam.Persongroup
from Persongroupteam
where respparty in ('[[USERNAME]]')
ORDER BY RESPPARTY, PERSONGROUP;