
-- Tickets missing REPORTEDPRIORITY
select ', =' || ticketid from ticket
where class in ('SR', 'INCIDENT')
  and REPORTEDPRIORITY is null;

-- Tickets missing REPORTEDBY
select ', =' || ticketid from ticket
where class in ('SR', 'INCIDENT')
  and REPORTEDBY is null;

-- Tickets in NEW status
select ', =' || ticketid from ticket
where class in ('SR', 'INCIDENT')
  and status = 'NEW';