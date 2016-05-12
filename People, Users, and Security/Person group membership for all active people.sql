/*******************************************************************************
*  Show all person groups that all active people are members of
*******************************************************************************/

select respparty, listagg(persongroup, ', ') within group (order by respparty)
from persongroupteam
  join person on person.PERSONID = persongroupteam.RESPPARTY
where person.STATUS = 'ACTIVE'
--  and personid = '[[USERNAME]]'
group by persongroupteam.RESPPARTY
order by persongroupteam.RESPPARTY;