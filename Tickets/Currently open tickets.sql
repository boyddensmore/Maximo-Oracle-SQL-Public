select TICKET.TICKETID, TICKET.CLASS, TICKET.AFFECTEDPERSON,
  CLASSHIERARCHY.HIERARCHYPATH,
  TICKET.DESCRIPTION,
  ticket.reportdate,
  ticket.internalpriority,
  ticket.targetfinish,
  ticket.status
from ticket
  left join
    (select classstructureid, listagg(ancestorclassid, ' / ') within group (order by hierarchylevels desc) HIERARCHYPATH from classancestor group by classstructureid) CLASSHIERARCHY on TICKET.CLASSSTRUCTUREID = CLASSHIERARCHY.CLASSSTRUCTUREID
where 
  ticket.class in ('SR', 'INCIDENT')
  and not exists (select *
                  from RELATEDRECORD
                  where class = 'SR' and RELATEDRECCLASS = 'INCIDENT' and relatetype = 'FOLLOWUP'
                    and relatedrecord.recordkey = ticket.ticketid)
  and ticket.status not in ('CLOSED', 'RESOLVED', 'CANCELED', 'REJECTED')
order by TICKET.TICKETID;