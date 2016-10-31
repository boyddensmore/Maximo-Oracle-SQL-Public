/*******************************************************************************
*  SR creation distribution by members of different teams
*******************************************************************************/

select 
  case when (trunc(creationdate, 'MON') between to_date('01-JAN-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss') and to_date('01-APR-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss')) then INFERRED_GROUP.ownergroup else person.ownergroup end PRIMARY_GROUP,
--  person.ownergroup,
  person.displayname,
  to_char(trunc(creationdate, 'MON'), 'Mon yyyy') CREATION_MONTH,
  ticket.class,
  count(*) TOTAL
from ticket
  join person on person.personid = ticket.createdby
  join (select TKOWNERHISTORY.owner, TKOWNERHISTORY.ownergroup
    from TKOWNERHISTORY
    where owndate between to_date('01-JAN-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss') and to_date('01-MAY-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
    group by TKOWNERHISTORY.owner, TKOWNERHISTORY.ownergroup
    having count(*) = (select max(count(*))
                        from TKOWNERHISTORY TKHIST
                        where owndate between to_date('01-JAN-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss') and to_date('01-MAY-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
                          and TKHIST.owner = TKOWNERHISTORY.OWNER
                        group by TKHIST.OWNERGROUP)) INFERRED_GROUP on INFERRED_GROUP.OWNER = person.personid
where creationdate >= TO_DATE('01-JAN-16 00:00:00', 'dd-MON-yy hh24:mi:ss')
  and person.ownergroup not in ('CHAT_Q')
--  and PERSON.DISPLAYNAME = 'Densmore, Boyd'
--  and trunc(creationdate, 'MON') between to_date('01-FEB-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss') and to_date('01-FEB-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
group by 
  trunc(creationdate, 'MON'), ticket.class, 
  case when (trunc(creationdate, 'MON') between to_date('01-JAN-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss') and to_date('01-APR-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss')) then INFERRED_GROUP.ownergroup else person.ownergroup end, 
--  person.ownergroup,
  person.displayname
order by 
--  case when (trunc(creationdate, 'MON') between to_date('01-JAN-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss') and to_date('01-APR-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss')) then INFERRED_GROUP.ownergroup else person.ownergroup end, 
--  person.ownergroup,
  person.displayname, trunc(creationdate, 'MON'), ticket.class;