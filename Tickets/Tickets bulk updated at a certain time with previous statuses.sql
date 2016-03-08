select ticketid, listagg(status, ',') within group (order by ticketid, changedate desc)
from tkstatus
where ticketid in 
  (SELECT ticketid
  FROM tkstatus
  WHERE changeby = 'RRAJAN'
  AND TO_CHAR(changedate, 'dd-mm-yy hh:mi:ss') = '02-12-14 06:25:43')
and class = 'INCIDENT'
group by ticketid
order by listagg(status, ',') within group (order by ticketid, changedate desc);





status not in (select value from synonymdomain where maxvalue in ('CAN','COMP','CLOSE') and domainid='WOSTATUS') and istask=0 
and sysdate >= schedstart 
and sysdate <= schedfinish + interval '1' hour