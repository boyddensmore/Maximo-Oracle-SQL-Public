select distinct ticket.TICKETID, ticket.CLASSIFICATIONID CLASSIFICATION, ticket.status, count(woactivity.STATUS) OPEN_ACTIVITIES
from ticket
  join tkstatus on tkstatus.TICKETID = ticket.TICKETID
  join woactivity on woactivity.ORIGRECORDID = ticket.TICKETID
where ticket.status in ('RESOLVED', 'CLOSED')
  and woactivity.STATUS not in ('CLOSE', 'COMP', 'CAN', 'FAIL')
group by ticket.TICKETID, ticket.CLASSIFICATIONID, ticket.status;


select ticket.status TICKET_STATUS, tkstatus.ticketid, tkstatus.STATUS HIST_STATUS, 
  tkstatus.CHANGEBY, tkstatus.CHANGEDATE, ticket.CLASSIFICATIONID, 
  woactivity.STATUS WO_STATUS, woactivity.STATUSDATE WO_STATUSDATE,
  woactivity.DESCRIPTION, woactivity.OWNER, woactivity.OWNERGROUP
from tkstatus
  join ticket on tkstatus.TICKETID = ticket.TICKETID
  join woactivity on woactivity.ORIGRECORDID = ticket.TICKETID
where ticket.CLASSIFICATIONID = 'TERMINATION'
  and tkstatus.CHANGEBY = 'BDENSMOR'
  and ticket.status in ('RESOLVED', 'CLOSED')
  and tkstatus.STATUS in 'CLOSED'
  and woactivity.STATUSDATE = tkstatus.CHANGEDATE
  ;