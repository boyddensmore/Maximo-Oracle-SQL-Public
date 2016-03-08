/*******************************************************************************
*  Tickets which were open during the previous month - Join method
*******************************************************************************/
select 
  ticketid, reportdate, actualfinish,
  TO_CHAR(trunc(add_months(sysdate, -1), 'MON'), 'dd-MON-yy hh24:mi:ss') LAST_MONTH_START,
  TO_CHAR(trunc(sysdate, 'MON'), 'dd-MON-yy hh24:mi:ss') LAST_MONTH_END,
  TO_CHAR(trunc(sysdate, 'DAY')+1, 'dd-MON-yy hh24:mi:ss'),
  DATE_LIST.DAY
from ticket
  join
    (select rownum - 1 + trunc(add_months(sysdate, -1), 'MON') DAY
    from all_objects
    where rownum < (trunc(add_months(sysdate, 0), 'MON')-1) -
                   trunc(add_months(sysdate, -1), 'MON') + 2) DATE_LIST 
  on 
    (DATE_LIST.DAY >= reportdate 
    and (DATE_LIST.DAY <= actualfinish
      or (actualfinish is null and DATE_LIST.DAY <= trunc(sysdate, 'MON'))))
where reportdate >= TO_DATE('01-SEP-2015 00:00:00', 'dd-MON-yy hh24:mi:ss')
order by TICKET.TICKETID, DATE_LIST.DAY
;



/*******************************************************************************
*  Tickets which were open during the previous month - Exists method
*******************************************************************************/
select 
  ticketid, reportdate, actualfinish,
  TO_CHAR(trunc(add_months(sysdate, -1), 'MON'), 'dd-MON-yy hh24:mi:ss') LAST_MONTH_START,
  TO_CHAR(trunc(sysdate, 'MON'), 'dd-MON-yy hh24:mi:ss') LAST_MONTH_END,
  TO_CHAR(trunc(sysdate, 'DAY')+1, 'dd-MON-yy hh24:mi:ss')
from ticket
where reportdate >= TO_DATE('01-SEP-2015 00:00:00', 'dd-MON-yy hh24:mi:ss')
  and exists
    (select rownum - 1 + trunc(add_months(sysdate, -1), 'MON') DAY
    from all_objects
    where rownum < (trunc(add_months(sysdate, 0), 'MON')-1) -
                   trunc(add_months(sysdate, -1), 'MON') + 2)
    and (rownum - 1 + trunc(add_months(sysdate, -1), 'MON') >= reportdate
    and (rownum - 1 + trunc(add_months(sysdate, -1), 'MON') <= actualfinish
      or (actualfinish is null and rownum - 1 + trunc(add_months(sysdate, -1), 'MON') <= trunc(sysdate, 'MON'))))
order by ticketid
;