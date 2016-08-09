

select PERSONGROUP.persongroup, PERSONGROUP.description, PERSONGROUP.ex_manager, 
--  (select min(changedate) from tkstatus where tkstatus.ownergroup = persongroup.persongroup) FIRST_ASSIGNMENT,
  FIRST_ASSIGNMENT.first_date,
  LAST_ASSIGNMENT.FIRST_DATE,
  MEMBER_COUNT.count MEMBER_COUNT
from PERSONGROUP
  left join (select ownergroup, min(changedate) first_date from tkstatus group by ownergroup) FIRST_ASSIGNMENT on FIRST_ASSIGNMENT.ownergroup = persongroup.persongroup
  left join (select ownergroup, max(changedate) first_date from tkstatus group by ownergroup) LAST_ASSIGNMENT on LAST_ASSIGNMENT.ownergroup = persongroup.persongroup
  left join (select persongroupteam.persongroup, count(*) count from persongroupteam group by persongroupteam.persongroup) MEMBER_COUNT on MEMBER_COUNT.persongroup = persongroup.persongroup
where PERSONGROUP.persongroup not in ('CHAT_Q', 'G_EXT_SD')
order by PERSONGROUP.persongroup;


