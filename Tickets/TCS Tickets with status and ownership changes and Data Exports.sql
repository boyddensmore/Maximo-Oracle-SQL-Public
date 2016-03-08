-- Ignore non-key statuses
-- Get everything into one row

-- listagg(status, ',') within group (order by ticketid, changedate desc)


-- List of users in TCS ownergroups
select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY'));

--Resolution details
/*******************************************************************************
*  Resolution details final
*******************************************************************************/
select ticket.Ticketid, ticket.Description, ticket.Owner, ticket.Ownergroup, ticket.Internalpriority, ticket.status, 
to_char(ticket.Reportdate, 'mm-dd-yyyy hh:mi:ss') REPORTED_DATE, ticket.Reportedby, Tkstatus.Status, to_char(Tkstatus.Changedate, 'mm-dd-yyyy hh:mi:ss') STATUS_CHANGE_DATE, 
Tkstatus.Owner, Tkstatus.Ownergroup
from ticket, Tkstatus
where Tkstatus.Ticketid = Ticket.Ticketid
and (Ticket.Ownergroup like 'TCS%'
--or Ticket.Ownergroup in ('IS COMP TELEPHY', 'SAP-SECURITY')
or ticket.owner in 
  (select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
--  or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY')
  )))
and ticket.class in ('INCIDENT', 'SR')
and Tkstatus.Status in ('RESOLVED')
--and Ticket.Reportdate >= to_date('11-26-14', 'mm-dd-yy')
order by Ticket.ticketid, tkstatus.changedate asc;


--Initial assignment details
select ticket.Ticketid, ticket.Description, ticket.Owner, ticket.Ownergroup, ticket.Internalpriority, ticket.status, 
to_char(ticket.Reportdate, 'mm-dd-yyyy hh:mi:ss') REPORTED_DATE, ticket.Reportedby, Tkstatus.Status, to_char(Tkstatus.Changedate, 'mm-dd-yyyy hh:mi:ss') STATUS_CHANGE_DATE, 
Tkstatus.Owner, Tkstatus.Ownergroup
from ticket, Tkstatus
where Tkstatus.Ticketid = Ticket.Ticketid
and (Ticket.Ownergroup like 'TCS%'
or Ticket.Ownergroup in ('IS COMP TELEPHY', 'SAP-SECURITY')
or ticket.owner in 
  (select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
  or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY'))))
and ticket.class in ('INCIDENT', 'SR')
and Tkstatus.Ownergroup is not null
-- Find first status with an owner or ownergroup is not null and is a TCS person or group.  This should be the first assignment.
and Tkstatusid = 
  (select min(Tkstatus.Tkstatusid) MIN_TKSTATUSID
  --ticketid, Changedate, Owner, Ownergroup, Status, tkstatusid
  from Tkstatus
  where 
  tkstatus.ticketid = Ticket.Ticketid
  and (tkstatus.Ownergroup like 'TCS%'
  or tkstatus.Ownergroup in ('IS COMP TELEPHY', 'SAP-SECURITY')
  or tkstatus.owner in 
    -- Find users in TCS person groups, in case a ticket is never assigned to the correct person group
    (select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
    or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY'))))
  and (owner is not null or ownergroup is not null));



select to_char(Changedate, 'mm-dd-yyyy hh:mi:ss') STATUS_CHANGE_DATE
from tkstatus
where Tkstatusid = 
  (select min(Tkstatus.Tkstatusid) MIN_TKSTATUSID
  --ticketid, Changedate, Owner, Ownergroup, Status, tkstatusid
  from Tkstatus
  where 
  tkstatus.ticketid = 'IN-1210'
  and (owner is not null or ownergroup is not null));
  
  
  
  
-- Combined query, not currently working.
select HeaderTicket.Ticketid, HeaderTicket.Description, HeaderTicket.Owner, HeaderTicket.Ownergroup, HeaderTicket.Internalpriority, HeaderTicket.status, 
to_char(HeaderTicket.Reportdate, 'mm-dd-yyyy hh:mi:ss') REPORTED_DATE, HeaderTicket.Reportedby, Tkstatus.Status, Initial_Assign.Assignment_Date , resolution.resolve_datetime, 
Tkstatus.Owner, Tkstatus.Ownergroup
from ticket HeaderTicket, Tkstatus, 
-- Initial Assignment subquery
  (select Ticket.Ticketid, to_char(Tkstatus.Changedate, 'mm-dd-yyyy hh:mi:ss') ASSIGNMENT_DATE, Tkstatus.Changeby
    from ticket, Tkstatus
    where Tkstatus.Ticketid = Ticket.Ticketid
    --Filters
    and (Ticket.Ownergroup like 'TCS%'
    or Ticket.Ownergroup in ('IS COMP TELEPHY', 'SAP-SECURITY')
    or ticket.owner in 
      (select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
      or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY'))))
    and ticket.class in ('INCIDENT', 'SR')
    and Tkstatus.Ownergroup is not null
    -- Find first status with an owner or ownergroup is not null and is a TCS person or group.  This should be the first assignment.
    and Tkstatusid = 
      (select min(Tkstatus.Tkstatusid) MIN_TKSTATUSID
      --ticketid, Changedate, Owner, Ownergroup, Status, tkstatusid
      from Tkstatus
      where tkstatus.ticketid = Ticket.Ticketid
      and Ticket.Ticketid = HeaderTicket.Ticketid
      and (tkstatus.Ownergroup like 'TCS%'
      or tkstatus.Ownergroup in ('IS COMP TELEPHY', 'SAP-SECURITY')
      or tkstatus.owner in 
        -- Find users in TCS person groups, in case a ticket is never assigned to the correct person group
        (select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
        or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY'))))
      and (owner is not null or ownergroup is not null))) INITIAL_ASSIGN,
-- Resolution subquery
  (select Ticket.Ticketid, to_char(Tkstatus.Changedate, 'mm-dd-yyyy hh:mi:ss') RESOLVE_DATETIME, Tkstatus.Changeby  
    from ticket, Tkstatus
    where Tkstatus.Ticketid = Ticket.Ticketid
    and Ticket.Ticketid = HeaderTicket.Ticketid
    --Filters
    and (Ticket.Ownergroup like 'TCS%'
    or Ticket.Ownergroup in ('IS COMP TELEPHY', 'SAP-SECURITY')
    or ticket.owner in 
      (select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
      or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY'))))
    and ticket.class in ('INCIDENT', 'SR')
    and Tkstatus.Status in ('RESOLVED')) RESOLUTION
where Tkstatus.ticketid = HeaderTicket.Ticketid
--Filters
and (HeaderTicket.Ownergroup like 'TCS%'
or HeaderTicket.Ownergroup in ('IS COMP TELEPHY', 'SAP-SECURITY')
or HeaderTicket.owner in 
  (select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
  or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY'))))
and HeaderTicket.class in ('INCIDENT', 'SR')
and Tkstatus.Status in ('RESOLVED')
--and Ticket.Reportdate >= to_date('11-26-14', 'mm-dd-yy')
order by HeaderTicket.ticketid, tkstatus.changedate asc;



--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------

select * 
from asset
where changedate > sysdate - 28;


select *
from classstructure;

select *
from tkownerhistory;

select *
from assetspec;

select *
from TKStatus;

-- List of tables to pull for export: ticket, tkstatus, tkownerhistory
-- Object structure exports for Locations, assets (subset)
-- All status details
select 
/* ticket.Ticketid, ticket.Description, ticket.Internalpriority, Classstructure.Classstructureid CLASSIFICATION_ID, Classstructure.Description CLASSIFICATION_DESCRIPTION, to_char(ticket.Reportdate, 'mm-dd-yyyy hh:mi:ss') REPORTED_DATE, to_char(Ticket.Actualfinish, 'mm-dd-yyyy hh:mi:ss') ACTUAL_FINISH, Ticket.Affectedperson, Person.Department,
ticket.Owner CURRENT_OWNER, ticket.Ownergroup CURRENT_OWNER_GROUP, ticket.status CURRENT_STATUS, 
Tkstatus.Status HISTORICAL_STATUS, to_char(Tkstatus.Changedate, 'mm-dd-yyyy hh:mi:ss') STATUS_CHANGE_DATE, 
Tkstatus.Owner HISTORICAL_STATUS_OWNER, Tkstatus.Ownergroup HISTORICAL_STATUS_OWNERGROUP */
ticket.*, tkstatus.*, person.*, classstructure.*
from ticket, Tkstatus, person, classstructure
where Tkstatus.Ticketid = Ticket.Ticketid
and person.personid = Ticket.Affectedperson
and Ticket.Classstructureid = Classstructure.Classstructureid
-- Filters
and (Ticket.Ownergroup like 'TCS%'
or Ticket.Ownergroup in ('IS COMP TELEPHY', 'SAP-SECURITY')
or ticket.owner in 
  (select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
  or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY'))))
and ticket.class in ('INCIDENT', 'SR', 'PROBLEM')
order by Ticket.Ticketid, Tkstatus.Changedate;


--All tickets which have been assigned to TCS
select distinct(ticketid)
from tkstatus
where (Ownergroup like 'TCS%'
or Ownergroup in ('IS COMP TELEPHY', 'SAP-SECURITY')
or owner in 
  (select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
  or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY'))));



select *
from wostatus, wochange, woownerhistory
where Wostatus.Wonum = wochange.wonum
and Woownerhistory.Wonum = wochange.wonum;


select wonum
from wochange
where (Ownergroup like 'TCS%'
or Ownergroup in ('IS COMP TELEPHY', 'SAP-SECURITY')
or owner in 
  (select distinct(respparty) from Persongroupteam where (persongroup like 'TCS%'
  or persongroup in ('IS COMP TELEPHY', 'SAP-SECURITY'))));