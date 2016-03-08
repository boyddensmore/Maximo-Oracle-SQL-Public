/*******************************************************************************
* P4 incident resolution example
*******************************************************************************/

select actualfinish, 
  targetfinish, 
  round(actualfinish - targetfinish, 2),
  round(((actualfinish - targetfinish) * 24), 2), 
  case when ((actualfinish - targetfinish) * 24) >= 60 then '1' else '0' end,
  case when ((actualfinish - targetfinish) * 24) > 0 then '1' else '0' end
from ticket
where (actualfinish - targetfinish) > 0
  and (actualfinish - targetfinish) < 4;



select to_date('03-01-2015', 'mm-dd-yyyy') Target_Finish1,
  to_date('03-03-2015', 'mm-dd-yyyy') Actual_finish1,
  to_date('03-03-2015', 'mm-dd-yyyy') - to_date('03-01-2015', 'mm-dd-yyyy') Delta1,
  to_number((to_date('03-03-2015', 'mm-dd-yyyy') - to_date('03-01-2015', 'mm-dd-yyyy')) * 24) Delta_hrs1,
  case when to_number((to_date('03-03-2015', 'mm-dd-yyyy') - to_date('03-01-2015', 'mm-dd-yyyy')) * 24) >= 60 then 'Breach' else 'No Breach' end Breach_Result1,
  NULL SPACER,
  to_date('03-01-2015', 'mm-dd-yyyy') Target_Finish2,
  to_date('03-04-2015', 'mm-dd-yyyy') Actual_finish2,
  to_date('03-04-2015', 'mm-dd-yyyy') - to_date('03-01-2015', 'mm-dd-yyyy') Delta2,
  to_number((to_date('03-04-2015', 'mm-dd-yyyy') - to_date('03-01-2015', 'mm-dd-yyyy')) * 24) Delta_hrs2,
  case when to_number((to_date('03-04-2015', 'mm-dd-yyyy') - to_date('03-01-2015', 'mm-dd-yyyy')) * 24) >= 60 then 'Breach' else 'No Breach' end Breach_Result2
from dual;