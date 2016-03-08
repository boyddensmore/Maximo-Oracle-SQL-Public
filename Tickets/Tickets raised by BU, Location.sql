/*******************************************************************************
*  Tickets raised in the past day, by BU
*******************************************************************************/

select person.ex_businessunit, class, count(*),
  round((count(*) / (select count(*) from ticket where reportdate >= sysdate - 1 and class = MAIN_TICKET.class)) * 100, 2) PERCENTAGE
from ticket MAIN_TICKET
  join person on person.personid = MAIN_TICKET.affectedperson
  join LOCANCESTOR on locancestor.location = MAIN_TICKET.location
  join LOCATIONS PARENT_BUILDING on PARENT_BUILDING.location = locancestor.ancestor
  join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = PARENT_BUILDING.CLASSSTRUCTUREID
where reportdate >= sysdate - 1
  and classstructure.classificationid = 'BUILDING'
  and class in ('SR', 'INCIDENT')
  and class in ('INCIDENT')
group by person.ex_businessunit, class
order by count(*) desc
;


/*******************************************************************************
*  Tickets raised in the past day, by Dept
*******************************************************************************/

select PERSON.DEPARTMENT, class, count(*),
  round((count(*) / (select count(*) from ticket where reportdate >= sysdate - 1 and class = MAIN_TICKET.class)) * 100, 2) PERCENTAGE
from ticket MAIN_TICKET
  join person on person.personid = MAIN_TICKET.affectedperson
  join LOCANCESTOR on locancestor.location = MAIN_TICKET.location
  join LOCATIONS PARENT_BUILDING on PARENT_BUILDING.location = locancestor.ancestor
  join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = PARENT_BUILDING.CLASSSTRUCTUREID
where reportdate >= sysdate - 1
  and classstructure.classificationid = 'BUILDING'
  and class in ('SR', 'INCIDENT')
  and class in ('INCIDENT')
group by PERSON.DEPARTMENT, class
order by count(*) desc
;


/*******************************************************************************
*  Tickets raised in the past day, by building
*******************************************************************************/

select PARENT_BUILDING.location BUILDING, class, count(*),
  round((count(*) / (select count(*) from ticket where reportdate >= sysdate - 1 and class = MAIN_TICKET.class)) * 100, 2) PERCENTAGE
from ticket MAIN_TICKET
  join person on person.personid = MAIN_TICKET.affectedperson
  join LOCANCESTOR on locancestor.location = MAIN_TICKET.location
  join LOCATIONS PARENT_BUILDING on PARENT_BUILDING.location = locancestor.ancestor
  join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = PARENT_BUILDING.CLASSSTRUCTUREID
where reportdate >= sysdate - 1
  and classstructure.classificationid = 'BUILDING'
  and class in ('SR', 'INCIDENT')
  and class in ('INCIDENT')
group by PARENT_BUILDING.location, class
order by count(*) desc
;


/*******************************************************************************
*  Tickets raised in the past day, by CI
*******************************************************************************/

select CI.CINAME, MAIN_TICKET.class, count(*),
  round((count(*) / (select count(*) from ticket where reportdate >= sysdate - 1 and class = MAIN_TICKET.class)) * 100, 2) PERCENTAGE
from ticket MAIN_TICKET
  left join person on person.personid = MAIN_TICKET.affectedperson
  left join LOCANCESTOR on locancestor.location = MAIN_TICKET.location
  left join LOCATIONS PARENT_BUILDING on PARENT_BUILDING.location = locancestor.ancestor
  left join classstructure on CLASSSTRUCTURE.CLASSSTRUCTUREID = PARENT_BUILDING.CLASSSTRUCTUREID
  join ci on MAIN_TICKET.CINUM = CI.CINUM
where reportdate >= sysdate - 1
  and classstructure.classificationid = 'BUILDING'
  and class in ('SR', 'INCIDENT')
  and class in ('INCIDENT')
  and MAIN_TICKET.cinum is not null
group by CI.CINAME, MAIN_TICKET.class
order by count(*) desc
;

