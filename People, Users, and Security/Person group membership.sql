/*******************************************************************************
*  Show all person groups that all active people are members of
*******************************************************************************/

select respparty, listagg(persongroup, ', ') within group (order by respparty)
from persongroupteam
  join person on person.PERSONID = persongroupteam.RESPPARTY
where person.STATUS = 'ACTIVE'
--  and personid = '[[PERSONID]]'
group by persongroupteam.RESPPARTY
order by persongroupteam.RESPPARTY;



/*******************************************************************************
*  Infer default group based on number of assignments during a given time period.
*******************************************************************************/

select TKOWNERHISTORY.owner userid, TKOWNERHISTORY.ownergroup, count(*) CNT
from TKOWNERHISTORY
  join person on person.personid = TKOWNERHISTORY.OWNER
where owndate between to_date('01-JAN-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss') and to_date('01-MAY-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
  and owner != '[[PERSONID]]'
group by TKOWNERHISTORY.owner, TKOWNERHISTORY.ownergroup, PERSON.OWNERGROUP
having count(*) = (select max(count(*))
                    from TKOWNERHISTORY TKHIST
                    where owndate between to_date('01-JAN-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss') and to_date('01-MAY-2016 00:00:00', 'dd-MON-yyyy hh24:mi:ss')
                      and TKHIST.owner = TKOWNERHISTORY.OWNER
                    group by TKHIST.OWNERGROUP)
order by TKOWNERHISTORY.OWNER
;
