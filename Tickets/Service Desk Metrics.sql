
/*******************************************************************************
*  Tickets logged by agent by date
*******************************************************************************/
select Createdby, count(ticketid) TICKETS
from ticket
where createdby in 
  (select Respparty
  from Persongroupteam
  where Persongroup = 'SERVICE DESK')
and Ticket.Creationdate Between to_date('01-01-2015', 'DD-MM-YYYY') and to_date('01-02-2015', 'DD-MM-YYYY') + 1
group by Createdby
order by Createdby;


/*******************************************************************************
*  Tickets assignments to agent by date
*******************************************************************************/
select owner, count(Ticketid)
from Tkownerhistory
where owner in (select Respparty
from Persongroupteam
where Persongroup = 'SERVICE DESK')
  and (Assignedownergroup is null or Assignedownergroup = 'SERVICE DESK')
and owndate >= to_date('2015/01/01', 'yyyy/mm/dd')
and owndate <= to_date('2015/02/01', 'yyyy/mm/dd') + 1
group by owner
order by owner;


/*******************************************************************************
* eForms logged
*******************************************************************************/
select Hierarchypath.Hierarchypath CLASSIFICATION_HIERARCHY, count(Ticket.Ticketid) TICKETS
from ticket
  join
    /* Generate HIERARCHYPATH by navigating parents for ClassStructure */
    (select Classstructure.Classstructureid,
      Classstructure.description,
        case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
        case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
        case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
        case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
        Classstructure.Classificationid HIERARCHYPATH
    from Classstructure
      left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
      left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
      left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
      left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid) Hierarchypath on Hierarchypath.Classstructureid = Ticket.Classstructureid
where ticket.Classstructureid in ('1107', '1257', '1258', '1259', '1260', '1250', '1247')
and Ticket.Reportdate >= to_date('2015/01/01', 'yyyy/mm/dd')
and Ticket.Reportdate <= to_date('2015/02/01', 'yyyy/mm/dd') + 1
group by Hierarchypath.Hierarchypath
order by Hierarchypath.Hierarchypath;


/*******************************************************************************
*  eForms resolved by agent, date
*******************************************************************************/
select Hierarchypath.hierarchypath, Tkstatus.changeby, count(ticket.ticketid) TICKETS
from Tkstatus
  join ticket on Ticket.Ticketid = Tkstatus.Ticketid
  join
      /* Generate HIERARCHYPATH by navigating parents for ClassStructure */
      (select Classstructure.Classstructureid,
        Classstructure.description,
          case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
          case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
          case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
          case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
          Classstructure.Classificationid HIERARCHYPATH
      from Classstructure
        left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
        left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
        left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
        left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid) Hierarchypath on Hierarchypath.Classstructureid = Ticket.Classstructureid
where Tkstatus.status = 'RESOLVED'
  /* Ticket was resolved by Service Desk agent */
  and Tkstatus.changeby in (select Respparty
    from Persongroupteam
    where Persongroup = 'SERVICE DESK')
  /* Ticket is for specific eForm */
  and ticket.Classstructureid in ('1107', '1257', '1258', '1259', '1260', '1250', '1247')
  /* TicketStatus is definitely the final resolution status change */
  and Ticket.Actualfinish = Tkstatus.Changedate
  and Ticket.Actualfinish >= to_date('2015/01/20', 'yyyy/mm/dd')
  and Ticket.Actualfinish <= to_date('2015/01/22', 'yyyy/mm/dd') + 1
group by Hierarchypath.hierarchypath, Tkstatus.changeby
order by Hierarchypath.hierarchypath, Tkstatus.changeby;


/*******************************************************************************
*  Non-eForm tickets actioned or resolved by agent, date
*******************************************************************************/
  
select ACTIONBY, count(distinct TICKET) TICKETS
from
  (select Tkstatus.changeby ACTIONBY, 'RESOLVE' ACTION, Tkstatus.Changedate ACTIONDATE, Tkstatus.Ticketid TICKET, Ticket.Classstructureid
      from Tkstatus
        join ticket on Ticket.Ticketid = Tkstatus.Ticketid
      where Tkstatus.status = 'RESOLVED'
        /* TicketStatus is definitely the final resolution status change */
        and Ticket.Actualfinish = Tkstatus.Changedate
  UNION
  Select Worklog.Modifyby ACTIONBY, 'WORKLOG' ACTION, Worklog.Modifydate ACTIONDATE, Worklog.Recordkey TICKET, Ticket.Classstructureid
      From Worklog
        join Ticket on Ticket.Ticketid = Worklog.Recordkey
  UNION
  select Commlog.Createby, 'COMMLOG' ACTION, Commlog.Createdate ACTIONDATE, Ticket.Ticketid TICKET, Ticket.Classstructureid
  from Commlog
    join Ticket on Commlog.Ownerid = Ticket.Ticketuid
  where Commlog.Orgobject is null
    and Commlog.Subject not like 'Automatic reply: %')
where 
  /* Ticket is not for specific eForm, these are reported separately */
  Classstructureid not in ('1107', '1257', '1258', '1259', '1260', '1250', '1247')
  and ACTIONDATE >= to_date('2015/01/20', 'yyyy/mm/dd')
  and ACTIONDATE <= to_date('2015/01/22', 'yyyy/mm/dd') + 1
  /* Ticket was actioned by Service Desk agent */
  and ACTIONBY in (select Respparty
    from Persongroupteam
    where Persongroup = 'SERVICE DESK')
group by ACTIONBY;

