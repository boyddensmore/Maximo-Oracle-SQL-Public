/*******************************************************************************
*  SLA Compliance by month and ticket class
*
* Note: Excludes ticket from before SR/INCIDENT 2.0. Because tickets before this
*   date do not generally have adjustedtargetresolutiontime, the total counts 
*   and percentages are not accurate.
*******************************************************************************/

select to_char(trunc(actualfinish, 'MON'), 'MON-yyyy') MONTHRESOLVED,
  class, 
  case when actualfinish <= adjustedtargetresolutiontime then 'SLA MET' else 'SLA NOT MET' end SLA_COMPLIANCE, 
  count(*),
  sum(count(*)) over(partition by trunc(actualfinish, 'MON'), class) TOTAL_COUNT,
  round(100*(count(*) / sum(count(*)) over (partition by trunc(actualfinish, 'MON'), class)),2) percent
from ticket
where status in ('CLOSED')
  -- Special case to exclude ticket from before SR/INCIDENT 2.0.
  and actualfinish >= to_date('01-JUL-15 00:00:00', 'dd-MON-yy hh24:mi:ss')
  -- Show tickets resolved within the past 12 months
  and actualfinish >= add_months(trunc(sysdate,'mm'),-12)
  -- Exclude the current month to ensure monthly counts are complete.  We may want another query for current month.
  and actualfinish <= last_day(add_months(trunc(sysdate,'mm'),-1))+1
  and adjustedtargetresolutiontime is not null
--  and owner = 'BDENSMOR'
--  and ownergroup = 'MAXITSUPPORT'
group by trunc(actualfinish, 'MON'), class, case when actualfinish <= adjustedtargetresolutiontime then 'SLA MET' else 'SLA NOT MET' end
order by trunc(actualfinish, 'MON'), class desc, case when actualfinish <= adjustedtargetresolutiontime then 'SLA MET' else 'SLA NOT MET' end asc
;