select ticket.ticketid, Ticket.Classificationid, Ticket.Affectedperson, Ticket.Status as "TICKET_STATUS", workorder.wonum, Workorder.Status as "ACTIVITY_STATUS", Workorder.Description, Workorder.Owner, Workorder.Ownergroup
from MAXIMO.Ticket ticket,
MAXIMO.Workorder workorder
where Workorder.Origrecordid = Ticket.Ticketid
and ticket.class = 'SR'
and Workorder.Woclass = 'ACTIVITY'
and Workorder.Status not in ('COMP', 'CLOSE')
and Ticket.Classificationid in ('TERMINATION', 'TRANSFER-COC', 'TRANSFER-NON COC', 'TRANSFER-SAME')
and (
  workorder.ownergroup in ('IS REG CUS/ASST', 'IS REG GIS/DSK')
  or
  workorder.owner in (select Respparty from maximo.persongroupteam where persongroup in ('IS REG CUS/ASST', 'IS REG GIS/DSK'))
);