/*******************************************************************************
*  BD - To use, replace USERID on line 6 with the user in question.  Run this SQL as
*  a script (F5 in SQL Developer) and check the script output for all details.
*******************************************************************************/

define USERID = "'RHUANG'";

--Find all security groups a user is in
select Groupuser.Userid, Groupuser.Groupname
from groupuser
where Groupuser.Userid = &USERID;

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
where Groupuser.Userid in ('APRESSE', 'KMITCHE', 'KBAILEY');

select Persongroupteam.Respparty, Persongroupteam.Persongroup, ',=' || Persongroupteam.Persongroup
from Persongroupteam
where respparty in ('APRESSE', 'KMITCHE', 'KBAILEY')
ORDER BY RESPPARTY, PERSONGROUP;