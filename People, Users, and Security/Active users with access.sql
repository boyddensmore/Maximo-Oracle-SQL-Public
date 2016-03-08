select maxuser.userid, Person.Displayname, Person.Title
from maxuser, person person
where person.personid = maxuser.personid
and maxuser.status = 'ACTIVE'
and maxuser.userid in 
  (select distinct(userid)
  from groupuser
  where groupname not in ('MAXDEFLTREG', 'MAXEVERYONE', 'MAXADMIN', 'SCCDGUESTS', 'MAXREG'));