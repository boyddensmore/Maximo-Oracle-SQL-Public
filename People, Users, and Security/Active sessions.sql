
/*******************************************************************************
*  Count of sessions by UI and status
*******************************************************************************/

select servername, active, count(*) SESSION_COUNT
from MAXSESSION
where servername like 'MXUI%'
group by servername, active
order by servername, active;


/*******************************************************************************
*  All session details for UIs
*******************************************************************************/

select MAXSESSIONUID, SERVERHOST, SERVERNAME, USERID, DISPLAYNAME, CLIENTHOST, 
  TO_CHAR(LOGINDATETIME, 'dd-MON-yy hh24:mi:ss') LOGINDATETIME, APPLICATION, 
  TO_CHAR(SERVERTIMESTAMP, 'dd-MON-yy hh24:mi:ss') SERVERTIMESTAMP,
  TO_CHAR(LASTACTIVITY, 'dd-MON-yy hh24:mi:ss') LASTACTIVITY, CLIENTADDR
from MAXSESSION
where ISSYSTEM = '0'
--  and servername like 'MXUI%'
--  and servername in ('MXUI1')
;


/*******************************************************************************
*  Count of sessions by userid
*******************************************************************************/

select userid, count(*) SESSION_COUNT
from MAXSESSION
where servername like 'MXUI%'
  and ACTIVE = 1
group by userid
order by count(*) desc;


/*******************************************************************************
*  Sessions for a single user
*******************************************************************************/

select (SELECT sys_context('userenv','instance_name') FROM dual) environment, SERVERHOST, SERVERNAME,
  userid, APPLICATION, CLIENTHOST, CLIENTADDR, TO_CHAR(LASTACTIVITY, 'dd-MON-yy hh24:mi:ss') LASTACTIVITY, 
  TO_CHAR(SERVERTIMESTAMP, 'dd-MON-yy hh24:mi:ss') SERVERTIMESTAMP, MAXSESSIONUID
from MAXSESSION
where ACTIVE = 1
--  and servername like 'MXUI%'
  and userid in ('[[USERID]]')
;