ALTER SESSION SET CURRENT_SCHEMA = Maximo;


/* Original, not including NULL ownergroups */
/* Simplified for BIRT */
/* Replace sysdate with BirtDateTime.now() as a parameter, replace sysdate in SQL with ? */
SELECT Persongroup.Ex_Manager "Group Manager", Persongroup "Group", 
Case When Open_Tickets.Openticketcount is null Then 0
   Else Open_Tickets.Openticketcount End "Open Ticket Count",
Case When Recent_Tickets.Openticketcount is null Then 0
   Else Recent_Tickets.Openticketcount End "New Tickets in Past 24 hrs.",
Case When Pending_Tickets.Openticketcount is null Then 0
   Else Pending_Tickets.Openticketcount End "Tickets in Pending Status",
Case When (Open_Tickets.Openticketcount is null) or (round((Pending_Tickets.Openticketcount / Open_Tickets.Openticketcount)) is null) Then 0
   Else  round((Pending_Tickets.Openticketcount / Open_Tickets.Openticketcount), 2) End "Pending Status %",
Case When Breached_Tickets.Openticketcount is null Then 0
   Else Breached_Tickets.Openticketcount End "Breached Tickets",
Case When (Open_Tickets.Openticketcount is null) or (round((Breached_Tickets.Openticketcount / Open_Tickets.Openticketcount)) is null) Then 0
   Else  round((Breached_Tickets.Openticketcount / Open_Tickets.Openticketcount), 2) End "Breached %"
FROM maximo.persongroup
  /* Begin count of open tickets */
  LEFT OUTER JOIN 
    (SELECT Ownergroup, count(ticket.ticketid) OPENTICKETCOUNT
    FROM maximo.ticket
    WHERE (ticket.status in ('NEW','QUEUED','INPROG') or ticket.status like 'PEND%')
    AND (ticket.class        = 'SR'
    OR (ticket.class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and not contains(ticket.description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Ownergroup) OPEN_TICKETS on Persongroup.Persongroup = Open_Tickets.Ownergroup
  /* End count of open tickets */
  /* Begin count of tickets logged in last 24 hours */
  LEFT OUTER JOIN 
    (SELECT Ownergroup, count(ticket.ticketid) OPENTICKETCOUNT
    FROM maximo.ticket
    WHERE Ticket.Reportdate >= sysdate - 1
    AND (ticket.class        = 'SR'
    OR (ticket.class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and not contains(ticket.description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Ownergroup) RECENT_TICKETS on Persongroup.Persongroup = Recent_Tickets.Ownergroup
  /* End count of tickets logged in last 24 hours */
  /* Begin count of tickets in pending status */
  LEFT OUTER JOIN 
    (SELECT Ownergroup, count(ticket.ticketid) OPENTICKETCOUNT
    FROM maximo.ticket
    WHERE (ticket.status like 'PEND%')
    AND (ticket.class        = 'SR'
    OR (ticket.class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and not contains(ticket.description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Ownergroup) PENDING_TICKETS on Persongroup.Persongroup = Pending_Tickets.Ownergroup
  /* End count of tickets in pending status */
  /* Begin breached ticket count */
  LEFT OUTER JOIN 
    (SELECT Ownergroup, count(ticket.ticketid) OPENTICKETCOUNT
    FROM maximo.ticket
    WHERE (ticket.status in ('NEW','QUEUED','INPROG') and ticket.status not like 'PEND%')
    AND (ticket.class        = 'SR'
    OR (ticket.class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and Ticket.Targetfinish <= sysdate
    and not contains(ticket.description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Ownergroup) BREACHED_TICKETS on Persongroup.Persongroup = Breached_Tickets.Ownergroup
  /* End breached ticket count */
WHERE ex_manager is not null
order by Persongroup.Ex_Manager;



/* Updated to include null ownergroups. */
SELECT Persongroup.Ex_Manager GROUP_MANAGER, Persongroup.Persongroup,
Case When Open_Tickets.Openticketcount is null Then 0
   Else Open_Tickets.Openticketcount End OPEN_TICKET_COUNT,
Case When Recent_Tickets.Openticketcount is null Then 0
   Else Recent_Tickets.Openticketcount End NEW_TICKETS_IN_24_HRS,
Case When Pending_Tickets.Openticketcount is null Then 0
   Else Pending_Tickets.Openticketcount End TICKETS_IN_PENDING,
Case When (Open_Tickets.Openticketcount is null) or (round((Pending_Tickets.Openticketcount / Open_Tickets.Openticketcount))*100 is null) Then 0
   Else  round((Pending_Tickets.Openticketcount / Open_Tickets.Openticketcount)*100, 2) End PENDING_STATUS_PERCENT
FROM maximo.persongroup
  /* Begin count of open tickets */
  FULL OUTER JOIN 
    (SELECT Ownergroup, count(ticket.ticketid) OPENTICKETCOUNT
    FROM maximo.ticket
    WHERE (ticket.status in ('NEW','QUEUED','INPROG') or ticket.status like 'PEND%')
    AND (ticket.class        = 'SR'
    OR (ticket.class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and not contains(ticket.description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Ownergroup) OPEN_TICKETS on Persongroup.Persongroup = Open_Tickets.Ownergroup
  /* End count of open tickets */
  /* Begin count of tickets logged in last 24 hours */
  FULL OUTER JOIN 
    (SELECT Ownergroup, count(ticket.ticketid) OPENTICKETCOUNT
    FROM maximo.ticket
    WHERE Ticket.Reportdate >= sysdate - 1
    AND (ticket.class        = 'SR'
    OR (ticket.class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and not contains(ticket.description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Ownergroup) RECENT_TICKETS on Persongroup.Persongroup = Recent_Tickets.Ownergroup
  /* End count of tickets logged in last 24 hours */
  /* Begin count of tickets in pending status */
  FULL OUTER JOIN 
    (SELECT Ownergroup, count(ticket.ticketid) OPENTICKETCOUNT
    FROM maximo.ticket
    WHERE (ticket.status like 'PEND%')
    AND (ticket.class        = 'SR'
    OR (ticket.class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and not contains(ticket.description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Ownergroup) PENDING_TICKETS on Persongroup.Persongroup = Pending_Tickets.Ownergroup
  /* End count of tickets in pending status */
/* WHERE ex_manager is not null */
WHERE (persongroup.Persongroup not in ('EXNTWSVS', 'HR-WORKDAY', 'VENDOR-ACRODEX', 
       'BUSINESS ANLSIS', 'FIN AP/EX FUNC', 'HRIS FUNC', 'INFORMATICA', 'VENDOR-LONGVIEW', 
       'ENMAX BI', 'VENDOR-RICOH', 'RELEASE MGMT', 'ENCOMPASS TEST', 'G_EXT_SD', 'CHAT_Q', 
       'SAP NETWEAVER', 'EXSRVSVS', 'EXCHGT', 'EXCHGMGT', 'EXCHGB', 'EXCAB') 
       or persongroup.Persongroup is null
      )
order by Persongroup.Ex_Manager;


/*******************************************************************************
* Test using UNIONs instead of JOINs to avoid multiple (null) rows
*******************************************************************************/

/* Updated to include null ownergroups. */
SELECT Persongroup.Ex_Manager GROUP_MANAGER, Persongroup.Persongroup,
Case When Open_Tickets.Openticketcount is null Then 0
   Else Open_Tickets.Openticketcount End OPEN_TICKET_COUNT,
Case When Recent_Tickets.Openticketcount is null Then 0
   Else Recent_Tickets.Openticketcount End NEW_TICKETS_IN_24_HRS,
Case When Pending_Tickets.Openticketcount is null Then 0
   Else Pending_Tickets.Openticketcount End TICKETS_IN_PENDING,
Case When (Open_Tickets.Openticketcount is null) or (round((Pending_Tickets.Openticketcount / Open_Tickets.Openticketcount))*100 is null) Then 0
   Else  round((Pending_Tickets.Openticketcount / Open_Tickets.Openticketcount)*100, 2) End PENDING_STATUS_PERCENT
FROM maximo.persongroup
  /* Begin count of open tickets */
  FULL OUTER JOIN 
    (SELECT Ownergroup, count(ticket.ticketid) OPENTICKETCOUNT
    FROM maximo.ticket
    WHERE (ticket.status in ('NEW','QUEUED','INPROG') or ticket.status like 'PEND%')
    AND (ticket.class        = 'SR'
    OR (ticket.class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and not contains(ticket.description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Ownergroup) OPEN_TICKETS on Persongroup.Persongroup = Open_Tickets.Ownergroup
  /* End count of open tickets */
  /* Begin count of tickets logged in last 24 hours */
  FULL OUTER JOIN 
    (SELECT Ownergroup, count(ticket.ticketid) OPENTICKETCOUNT
    FROM maximo.ticket
    WHERE Ticket.Reportdate >= sysdate - 1
    AND (ticket.class        = 'SR'
    OR (ticket.class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and not contains(ticket.description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Ownergroup) RECENT_TICKETS on Persongroup.Persongroup = Recent_Tickets.Ownergroup
  /* End count of tickets logged in last 24 hours */
  /* Begin count of tickets in pending status */
  FULL OUTER JOIN 
    (SELECT Ownergroup, count(ticket.ticketid) OPENTICKETCOUNT
    FROM maximo.ticket
    WHERE (ticket.status like 'PEND%')
    AND (ticket.class        = 'SR'
    OR (ticket.class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and not contains(ticket.description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Ownergroup) PENDING_TICKETS on Persongroup.Persongroup = Pending_Tickets.Ownergroup
  /* End count of tickets in pending status */
/* WHERE ex_manager is not null */
WHERE (persongroup.Persongroup not in ('EXNTWSVS', 'HR-WORKDAY', 'VENDOR-ACRODEX', 
       'BUSINESS ANLSIS', 'FIN AP/EX FUNC', 'HRIS FUNC', 'INFORMATICA', 'VENDOR-LONGVIEW', 
       'ENMAX BI', 'VENDOR-RICOH', 'RELEASE MGMT', 'ENCOMPASS TEST', 'G_EXT_SD', 'CHAT_Q', 
       'SAP NETWEAVER', 'EXSRVSVS', 'EXCHGT', 'EXCHGMGT', 'EXCHGB', 'EXCAB') 
       or persongroup.Persongroup is null
      )
order by Persongroup.Ex_Manager;


/* Begin count of open tickets */
select group_manager, persongroup, sum(openticketcount) openticketcount, sum(new_tickets_in_24_hrs) new_tickets_in_24_hrs, sum(tickets_in_pending) tickets_in_pending, 
Case When (sum(openticketcount) is null) or (round((sum(tickets_in_pending) / sum(openticketcount)))*100 is null) Then 0
   Else  round((sum(tickets_in_pending) / sum(openticketcount))*100, 2) End PENDING_STATUS_PERCENT
from
(SELECT Persongroup.Ex_Manager GROUP_MANAGER, ticket.Ownergroup Persongroup, count(ticket.ticketid) OPENTICKETCOUNT, 0 NEW_TICKETS_IN_24_HRS, 0 TICKETS_IN_PENDING, 0 PENDING_STATUS_PERCENT
FROM Ticket
  left join Persongroup on Persongroup.persongroup = Ticket.Ownergroup
WHERE (Ticket.Status in ('NEW','QUEUED','INPROG') or ticket.status like 'PEND%')
AND (Ticket.Class        = 'SR'
OR (Ticket.Class         = 'INCIDENT'
AND Ticket.Origrecordid IS NULL))
and not contains(Ticket.Description,'  $20192  ') > 0
/* Ticket not classed as enhancement or "Personel" (resource request) */
and Ticket.Classstructureid not in ('1253', '1252')
group by Persongroup.Ex_Manager, Ticket.Ownergroup
/* End count of open tickets */
UNION
SELECT Persongroup.Ex_Manager GROUP_MANAGER, ticket.Ownergroup Persongroup, 0 OPENTICKETCOUNT, count(ticket.ticketid) NEW_TICKETS_IN_24_HRS, 0 TICKETS_IN_PENDING, 0 PENDING_STATUS_PERCENT
    FROM Ticket
      left join Persongroup on Persongroup.persongroup = Ticket.Ownergroup
    WHERE Ticket.Reportdate >= sysdate - 1
    AND (Ticket.class        = 'SR'
    OR (Ticket.class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and not contains(Ticket.Description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Persongroup.Ex_Manager, Ownergroup
  /* End count of tickets logged in last 24 hours */
UNION
SELECT 
Persongroup.Ex_Manager  GROUP_MANAGER, 
ticket.Ownergroup Persongroup, 0 OPENTICKETCOUNT, 0 NEW_TICKETS_IN_24_HRS, count(ticket.ticketid) TICKETS_IN_PENDING, 0 PENDING_STATUS_PERCENT
    FROM Ticket
      left join Persongroup on Persongroup.persongroup = Ticket.Ownergroup
    WHERE (Ticket.Status like 'PEND%')
    AND (Ticket.Class        = 'SR'
    OR (Ticket.Class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and not contains(Ticket.Description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Persongroup.Ex_Manager, Ownergroup
UNION
SELECT Persongroup.Ex_Manager GROUP_MANAGER, ticket.Ownergroup Persongroup, 0 OPENTICKETCOUNT, 0 NEW_TICKETS_IN_24_HRS, 0 TICKETS_IN_PENDING, count(ticket.ticketid) PENDING_STATUS_PERCENT
    FROM Ticket
      left join Persongroup on Persongroup.persongroup = Ticket.Ownergroup
    WHERE (Ticket.Status like 'PEND%')
    AND (Ticket.Class        = 'SR'
    OR (Ticket.Class         = 'INCIDENT'
    AND Ticket.Origrecordid IS NULL))
    and not contains(Ticket.Description,'  $20192  ') > 0
    /* Ticket not classed as enhancement or "Personel" (resource request) */
    and Ticket.Classstructureid not in ('1253', '1252')
    group by Persongroup.Ex_Manager, Ownergroup)
where (Persongroup not in ('EXNTWSVS', 'HR-WORKDAY', 'VENDOR-ACRODEX', 
       'BUSINESS ANLSIS', 'FIN AP/EX FUNC', 'HRIS FUNC', 'INFORMATICA', 'VENDOR-LONGVIEW', 
       'ENMAX BI', 'VENDOR-RICOH', 'RELEASE MGMT', 'ENCOMPASS TEST', 'G_EXT_SD', 'CHAT_Q', 
       'SAP NETWEAVER', 'EXSRVSVS', 'EXCHGT', 'EXCHGMGT', 'EXCHGB', 'EXCAB') 
       or Persongroup is null
      )
group by group_manager, persongroup;