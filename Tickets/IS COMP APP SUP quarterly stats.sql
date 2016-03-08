/*******************************************************************************
*  List of all Changes 
*******************************************************************************/

SELECT wonum, SCHEDSTART, SCHEDFINISH, status, owner, worklog.LOGTYPE, worklog.EXCHGRESULT, worklog.DESCRIPTION
FROM wochange
  JOIN worklog ON worklog.recordkey = wochange.wonum
WHERE (ownergroup IN ('IS COMP APP SUP')
  OR owner IN
    (SELECT respparty
    FROM persongroupteam
    WHERE persongroup IN ('IS COMP APP SUP')))
  and logtype = 'CHANGERESULT'
  and wochange.SCHEDSTART >= to_date('01-01-2015', 'mm-dd-yyyy')
  and wochange.SCHEDSTART < to_date('04-01-2015', 'mm-dd-yyyy')
order by schedstart;




/*******************************************************************************
*  Ticket assignment time - Average
*******************************************************************************/
select --MASTER_LIST.ticketid MASTER_TICKETID, 
--  INIT_GROUP.ownergroup IG_OWNERGROUP, INIT_GROUP.owner IG_OWNER, INIT_GROUP.ASSIGNEDOWNERGROUP IG_AOG,
--  PERSON_ASSIGN.ownergroup PA_OWNERGROUP, PERSON_ASSIGN.owner PA_OWNER, PERSON_ASSIGN.ASSIGNEDOWNERGROUP PA_AOG,
--  to_char(init_group.owndate, 'mm-dd-yy hh:mi:ss') IG_OWNDATE, to_char(PERSON_ASSIGN.owndate, 'mm-dd-yy hh:mi:ss') PA_OWNGROUP,
  round(avg(round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24), 2) AVGHOURS_TO_ASSIGN
--  trunc(round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24, 0) HOURS_TO_ASSIGN,
--  trunc((round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24 - trunc(round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24, 0)) * 60, 0) MINS_TO_ASSIGN,
--  trunc(round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24, 0) || ':' || LPAD(trunc((round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24 - trunc(round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24, 0)) * 60, 0), 2, '0') HM_TO_ASSIGN
from 
  (select distinct TKOWNERHISTORY.ticketid
  from TKOWNERHISTORY
  where TKOWNERHISTORY.owndate >= to_date('01-01-2015', 'mm-dd-yyyy')
    and TKOWNERHISTORY.owndate < to_date('04-01-2015', 'mm-dd-yyyy')
    and TKOWNERHISTORY.ASSIGNEDOWNERGROUP = 'IS COMP APP SUP'
  order by TKOWNERHISTORY.ticketid) MASTER_LIST
  join
  (select ticketid, ownergroup, owner, owndate, OWNERCHANGEBY, ASSIGNEDOWNERGROUP
  from TKOWNERHISTORY
  where owndate >= to_date('01-01-2015', 'mm-dd-yyyy')
    and owndate < to_date('04-01-2015', 'mm-dd-yyyy')
    and ASSIGNEDOWNERGROUP = 'IS COMP APP SUP'
    and owner is null
  order by ticketid, owndate) INIT_GROUP on MASTER_LIST.ticketid = INIT_GROUP.ticketid
  join
  (select ticketid, ownergroup, owner, owndate, OWNERCHANGEBY, ASSIGNEDOWNERGROUP
  from TKOWNERHISTORY
  where owndate >= to_date('01-01-2015', 'mm-dd-yyyy')
    and owndate < to_date('04-01-2015', 'mm-dd-yyyy')
    and ASSIGNEDOWNERGROUP = 'IS COMP APP SUP'
    and owner is not null
  order by ticketid, owndate) PERSON_ASSIGN on MASTER_LIST.ticketid = PERSON_ASSIGN.ticketid;



/*******************************************************************************
*  Ticket assignment time - Ticket list
*******************************************************************************/
select MASTER_LIST.ticketid MASTER_TICKETID, ticket.INTERNALPRIORITY,
--  INIT_GROUP.ownergroup IG_OWNERGROUP, INIT_GROUP.owner IG_OWNER, INIT_GROUP.ASSIGNEDOWNERGROUP IG_AOG,
--  PERSON_ASSIGN.ownergroup PA_OWNERGROUP, PERSON_ASSIGN.owner PA_OWNER, PERSON_ASSIGN.ASSIGNEDOWNERGROUP PA_AOG,
--  to_char(init_group.owndate, 'mm-dd-yy hh:mi:ss') IG_OWNDATE, to_char(PERSON_ASSIGN.owndate, 'mm-dd-yy hh:mi:ss') PA_OWNGROUP,
  round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24 AVGHOURS_TO_ASSIGN
--  trunc(round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24, 0) HOURS_TO_ASSIGN,
--  trunc((round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24 - trunc(round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24, 0)) * 60, 0) MINS_TO_ASSIGN,
--  trunc(round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24, 0) || ':' || LPAD(trunc((round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24 - trunc(round(PERSON_ASSIGN.owndate - init_group.owndate, 2) * 24, 0)) * 60, 0), 2, '0') HM_TO_ASSIGN
from 
  (select distinct TKOWNERHISTORY.ticketid
  from TKOWNERHISTORY
  where TKOWNERHISTORY.owndate >= to_date('01-01-2015', 'mm-dd-yyyy')
    and TKOWNERHISTORY.owndate < to_date('04-01-2015', 'mm-dd-yyyy')
    and TKOWNERHISTORY.ASSIGNEDOWNERGROUP = 'IS COMP APP SUP'
  order by TKOWNERHISTORY.ticketid) MASTER_LIST
  join
  (select ticketid, ownergroup, owner, owndate, OWNERCHANGEBY, ASSIGNEDOWNERGROUP
  from TKOWNERHISTORY
  where owndate >= to_date('01-01-2015', 'mm-dd-yyyy')
    and owndate < to_date('04-01-2015', 'mm-dd-yyyy')
    and ASSIGNEDOWNERGROUP = 'IS COMP APP SUP'
    and owner is null
  order by ticketid, owndate) INIT_GROUP on MASTER_LIST.ticketid = INIT_GROUP.ticketid
  join
  (select ticketid, ownergroup, owner, owndate, OWNERCHANGEBY, ASSIGNEDOWNERGROUP
  from TKOWNERHISTORY
  where owndate >= to_date('01-01-2015', 'mm-dd-yyyy')
    and owndate < to_date('04-01-2015', 'mm-dd-yyyy')
    and ASSIGNEDOWNERGROUP = 'IS COMP APP SUP'
    and owner is not null
  order by ticketid, owndate) PERSON_ASSIGN on MASTER_LIST.ticketid = PERSON_ASSIGN.ticketid
  join ticket on ticket.ticketid = MASTER_LIST.ticketid;
