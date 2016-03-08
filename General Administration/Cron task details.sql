

/*******************************************************************************
*  Instances/runs of ESCIBMSRCLS5 and ESCIBMINCCLS5
*******************************************************************************/

SELECT CRONTASKNAME,
  INSTANCENAME,
  SERVERNAME,
  SERVERHOST,
  ACTIVITY,
  TO_CHAR(STARTTIME, 'dd-MON-yy hh24:mi:ss') START_TIME,
  TRUNC((SYSDATE - STARTTIME) * 24 * 60, 2) MINS_SINCE_START,
  TO_CHAR(ENDTIME, 'dd-MON-yy hh24:mi:ss') END_TIME,
  RUNTIMEERROR,
  SEQUENCE
FROM CRONTASKHISTORY
WHERE CRONTASKNAME = 'ESCALATION'
    and INSTANCENAME in ('ESCEX_SRRESPONSE')
ORDER BY sequence desc;

/*******************************************************************************
*  Instances/runs of VMMSYNC
*******************************************************************************/

select CRONTASKNAME, INSTANCENAME, SERVERNAME, ACTIVITY, 
  TO_CHAR(STARTTIME, 'dd-MON-yy hh24:mi:ss'), 
  trunc((sysdate - STARTTIME) * 24 *60, 2) MINS_SINCE_START,  
  TO_CHAR(ENDTIME, 'dd-MON-yy hh24:mi:ss'), RUNTIMEERROR, SEQUENCE
from CRONTASKHISTORY
where CRONTASKNAME = 'VMMSYNC'
  and INSTANCENAME = 'VMMSYNC01'
order by STARTTIME desc;


/*******************************************************************************
*  Instances/runs - General testing
*******************************************************************************/

select CRONTASKNAME, INSTANCENAME, SERVERNAME, ACTIVITY, 
  TO_CHAR(STARTTIME, 'dd-MON-yy hh24:mi:ss') STARTTIME, 
  trunc((sysdate - STARTTIME) * 24 *60, 2) MINS_SINCE_START,  
  TO_CHAR(ENDTIME, 'dd-MON-yy hh24:mi:ss') ENDTIME, RUNTIMEERROR, SEQUENCE
from CRONTASKHISTORY
where CRONTASKNAME = 'ESCALATION'
  and INSTANCENAME = 'ESC1054'
order by SEQUENCE desc;