/*******************************************************************************
*  SR creation distribution by members of different teams
*******************************************************************************/

    select 
      trunc(creationdate, 'MON') CREATION_MONTH,
      count(*) TOTAL,
      '||',
      count(case when exists (select 1 from persongroupteam where persongroup like 'SERVICE DESK' and respparty = sr.createdby) then 1 else null end) SERVICEDESK,
      round(count(case when exists (select 1 from persongroupteam where persongroup like 'SERVICE DESK' and respparty = sr.createdby) then 1 else null end) / count(*) * 100, 2) SERVICEDESK_PCT,
      '||', 
      count(case when exists (select 1 from persongroupteam where persongroup like 'DESKSIDE' and respparty = sr.createdby) then 1 else null end) DESKSIDE,
      round(count(case when exists (select 1 from persongroupteam where persongroup like 'DESKSIDE' and respparty = sr.createdby) then 1 else null end) / count(*) * 100, 2) DESKSIDE_PCT,
      '||', 
      count(case when exists (select 1 from persongroupteam where persongroup like 'TCS%' and respparty = sr.createdby) then 1 else null end) TCSAGENT,
      round(count(case when exists (select 1 from persongroupteam where persongroup like 'TCS%' and respparty = sr.createdby) then 1 else null end) / count(*) * 100, 2) TCSAGENT_PCT,
      '||', 
      count(case when not exists (select 1 from persongroupteam where (persongroup like 'TCS%' or persongroup in ('SERVICE DESK', 'DESKSIDE')) and respparty = sr.createdby) then 1 else null end) ITIS,
      round(count(case when not exists (select 1 from persongroupteam where (persongroup like 'TCS%' or persongroup in ('SERVICE DESK', 'DESKSIDE')) and respparty = sr.createdby) then 1 else null end) / count(*) * 100, 2) ITIS_PCT
    from sr
    where creationdate >= TO_DATE('01-JUL-15 00:00:00', 'dd-MON-yy hh24:mi:ss')
    group by trunc(creationdate, 'MON')
    order by trunc(creationdate, 'MON');


/*******************************************************************************
*  Count of SRs created by individual
*******************************************************************************/

    select
      createdby, PERSONGROUPS, count(*)
    from sr
      join (select respparty, listagg(persongroup, ',') within group (ORDER BY persongroupteam.persongroup) PERSONGROUPS from persongroupteam group by respparty) persongroupteams on persongroupteams.respparty = sr.createdby
    group by createdby, PERSONGROUPS
    order by count(*) desc;


/*******************************************************************************
*  Count of tickets with no WF or SLA
*******************************************************************************/

    select 
      TICKETS.CLASS,  
      count(case when CREATEDBY in (select respparty from persongroupteam where persongroup = 'SERVICE DESK') and not exists (select 1 from wfinstance where ownerid = TICKETS.ticketuid) then 1 else null end) SD_CREATED,
      count(case when CREATEDBY not in (select respparty from persongroupteam where persongroup = 'SERVICE DESK') and not exists (select 1 from wfinstance where ownerid = TICKETS.ticketuid) then 1 else null end) NOT_SD_CREATED,
      count(case when not exists (select 1 from wfinstance where ownerid = TICKETS.ticketuid) then 1 else null end) TOTAL_NO_WF,
      count(case when exists (select 1 from slarecords where ownerid = TICKETS.ticketuid) then 1 else null end) HAS_SLA,
      count(case when not exists (select 1 from slarecords where ownerid = TICKETS.ticketuid) then 1 else null end) NO_SLA,
      count(*) TOTAL_TICKETS
    from ticket TICKETS
    where reportdate >= sysdate - 60
      and TICKETS.CLASS in ('SR', 'INCIDENT')
    group by TICKETS.CLASS;


/*******************************************************************************
*  Count/percent of email/voicemail tickets where REPORTDATE not updated
*******************************************************************************/

    select EXTERNALSYSTEM, trunc(creationdate, 'MON') MONTH,
      count(case when creationdate = reportdate then 'MATCH' else null end) MATCH_COUNT,
      count(case when creationdate <> reportdate then 'MATCH' else null end) NOT_MATCH_COUNT,
      count(*) TOTAL,
      round(count(case when creationdate = reportdate then 'MATCH' else null end) / count(*), 4)*100 MATCH_PCT,
      round(count(case when creationdate <> reportdate then 'MATCH' else null end) / count(*), 4)*100 NOT_MATCH_PCT
    from sr
    where EXTERNALSYSTEM in ('VOICEMAIL', 'EMAIL')
    --  and CREATIONDATE >= TO_DATE('01-OCT-15 00:00:00', 'dd-MON-yy hh24:mi:ss')
      and CREATIONDATE BETWEEN (sysdate - 120) and (sysdate - 0)
    group by EXTERNALSYSTEM, trunc(creationdate, 'MON')
    order by EXTERNALSYSTEM, trunc(creationdate, 'MON');


/*******************************************************************************
*  Number of teams involved in a ticket, by assignment
*******************************************************************************/

    select
      case  when cnt = 1 then '1' 
            when cnt = 2 then '2'
            when cnt = 3 then '3'
            when cnt = 4 then '4'
            when cnt = 5 then '5'
            when cnt = 6 then '6'
            when cnt = 7 then '7'
            when cnt >= 8 then '8+' end NUM_OF_TEAMS,
      count(*)
    from
      (select ticketid, count(*) CNT
      from
        (select distinct ticketid, ownergroup
        from TKOWNERHISTORY
        where owndate >= sysdate - 690
          -- MAXITSUPPORT, DPHUI, and BDENSMOR have a number of testing tickets.
          -- Safest to simply exclude them.
          and ownergroup != 'MAXITSUPPORT'
          and owner not in ('DPHUI', 'BDENSMOR'))
      group by ticketid)
    group by case when cnt = 1 then '1' 
                  when cnt = 2 then '2'
                  when cnt = 3 then '3'
                  when cnt = 4 then '4'
                  when cnt = 5 then '5'
                  when cnt = 6 then '6'
                  when cnt = 7 then '7'
                  when cnt >= 8 then '8+' end
    order by case when cnt = 1 then '1' 
                  when cnt = 2 then '2'
                  when cnt = 3 then '3'
                  when cnt = 4 then '4'
                  when cnt = 5 then '5'
                  when cnt = 6 then '6'
                  when cnt = 7 then '7'
                  when cnt >= 8 then '8+' end
    ;


/*******************************************************************************
*  Instances of tickets being assigned to multiple groups in a 2 hour window
*******************************************************************************/

select *
from
  (select t1.ticketid, count(*) CNT
  from tkstatus t1
    join tkstatus t2 on
      T1.TICKETID = T2.TICKETID
      and T2.OWNERGROUP != T1.OWNERGROUP
      and abs(T1.CHANGEDATE - T2.CHANGEDATE) < (120 / (24 * 60))
      and t1.status = t2.status
      and T2.CHANGEDATE > T1.CHANGEDATE
  where T1.CHANGEDATE >= sysdate - 90
    and t1.status in ('INPROG')
--    and t1.class = 'SR'
  group by t1.ticketid
  order by count(*) desc)
where CNT > 1
;