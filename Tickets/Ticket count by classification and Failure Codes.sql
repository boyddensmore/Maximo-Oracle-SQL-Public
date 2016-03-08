/*******************************************************************************
*  Count of SRs by classification
*******************************************************************************/

select CLASSSTRUCTURE.CLASSSTRUCTUREID,
  case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid HIERARCHYPATH, count(*)
from SR
  join CLASSSTRUCTURE on SR.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
  left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
  left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
  left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
  left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid
group by CLASSSTRUCTURE.CLASSSTRUCTUREID,
  case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid
order by case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid;



/*******************************************************************************
*  Count of incident SRs first-time-fixed by Service Desk by month and classification
*******************************************************************************/

select to_char(SR.CREATIONDATE, 'Mon yyyy') MONTH_LOGGED,
--  case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
--  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
--  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
--  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
--  Classstructure.Classificationid HIERARCHYPATH, 
  count(*)
from SR
  join CLASSSTRUCTURE on SR.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
  left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
  left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
  left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
  left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid
where exists (select PERSONGROUPTEAM.RESPPARTY from PERSONGROUPTEAM where PERSONGROUPTEAM.PERSONGROUP = 'SERVICE DESK' and PERSONGROUPTEAM.RESPPARTY = SR.CREATEDBY)
  and EX_FCR = 1
  and exists (select 1 from maximo.classancestor where ancestor = '1019' and classstructureid=sr.classstructureid)
  and SR.CREATIONDATE >= to_date('01-01-2015', 'mm-dd-yyyy')
  and SR.CREATIONDATE <= to_date('01-01-2016', 'mm-dd-yyyy')
group by rollup(to_char(SR.CREATIONDATE, 'Mon yyyy'))
--  , case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
--  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
--  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
--  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
--  Classstructure.Classificationid
order by 
    case 
       when to_char(SR.CREATIONDATE, 'Mon yyyy') = 'Jan 2015' then 1 
       when to_char(SR.CREATIONDATE, 'Mon yyyy') = 'Feb 2015' then 2
       when to_char(SR.CREATIONDATE, 'Mon yyyy') = 'Mar 2015' then 3
       when to_char(SR.CREATIONDATE, 'Mon yyyy') = 'Apr 2015' then 4
       when to_char(SR.CREATIONDATE, 'Mon yyyy') = 'May 2015' then 5
       when to_char(SR.CREATIONDATE, 'Mon yyyy') = 'Jun 2015' then 6
       when to_char(SR.CREATIONDATE, 'Mon yyyy') = 'Jul 2015' then 7
       when to_char(SR.CREATIONDATE, 'Mon yyyy') = 'Aug 2015' then 8
       when to_char(SR.CREATIONDATE, 'Mon yyyy') = 'Sep 2015' then 9
       when to_char(SR.CREATIONDATE, 'Mon yyyy') = 'Oct 2015' then 10
       when to_char(SR.CREATIONDATE, 'Mon yyyy') = 'Nov 2015' then 11
       when to_char(SR.CREATIONDATE, 'Mon yyyy') = 'Dec 2015' then 12
       else 13
    end
--    , case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
--    case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
--    case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
--    case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
--    Classstructure.Classificationid
    ;


/*******************************************************************************
*  Average length of resolution details on SD FCRd SRs classified as INCs
*******************************************************************************/

select
  case
    when length(LONGDESCRIPTION.LDTEXT) > 10000 then '8. Over 10000'
    when length(LONGDESCRIPTION.LDTEXT) > 1000 then '7. 1000-10000'
    when length(LONGDESCRIPTION.LDTEXT) > 500 then '6. 500-1000'
    when length(LONGDESCRIPTION.LDTEXT) > 400 then '5. 400-500'
    when length(LONGDESCRIPTION.LDTEXT) > 300 then '4. 300-400'
    when length(LONGDESCRIPTION.LDTEXT) > 200 then '3. 200-300'
    when length(LONGDESCRIPTION.LDTEXT) > 100 then '2. 100-200'
    when length(LONGDESCRIPTION.LDTEXT) > 0 then '1. 0-100'
    else 'OTHER'
  end LENGTH_RANGE,
  sr.ticketid,
  count(*)
from SR
  join LONGDESCRIPTION on SR.TICKETUID = LONGDESCRIPTION.LDKEY
  join CLASSSTRUCTURE on SR.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
  left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
  left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
  left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
  left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid
where exists (select PERSONGROUPTEAM.RESPPARTY from PERSONGROUPTEAM where PERSONGROUPTEAM.PERSONGROUP = 'SERVICE DESK' and PERSONGROUPTEAM.RESPPARTY = SR.CREATEDBY)
  and EX_FCR = 1
  and exists (select 1 from maximo.classancestor where ancestor = '1019' and classstructureid=sr.classstructureid)
  and SR.CREATIONDATE >= to_date('01-01-2015', 'mm-dd-yyyy')
  and SR.CREATIONDATE <= to_date('01-01-2016', 'mm-dd-yyyy')
  and LONGDESCRIPTION.LDOWNERCOL in ('PROBLEMCODE', 'FR1CODE', 'FR2CODE')
  and LONGDESCRIPTION.LDOWNERTABLE = 'TICKET'
group by
  case
    when length(LONGDESCRIPTION.LDTEXT) > 10000 then '8. Over 10000'
    when length(LONGDESCRIPTION.LDTEXT) > 1000 then '7. 1000-10000'
    when length(LONGDESCRIPTION.LDTEXT) > 500 then '6. 500-1000'
    when length(LONGDESCRIPTION.LDTEXT) > 400 then '5. 400-500'
    when length(LONGDESCRIPTION.LDTEXT) > 300 then '4. 300-400'
    when length(LONGDESCRIPTION.LDTEXT) > 200 then '3. 200-300'
    when length(LONGDESCRIPTION.LDTEXT) > 100 then '2. 100-200'
    when length(LONGDESCRIPTION.LDTEXT) > 0 then '1. 0-100'
    else 'OTHER'
  end,
  sr.ticketid
order by case
    when length(LONGDESCRIPTION.LDTEXT) > 10000 then '8. Over 10000'
    when length(LONGDESCRIPTION.LDTEXT) > 1000 then '7. 1000-10000'
    when length(LONGDESCRIPTION.LDTEXT) > 500 then '6. 500-1000'
    when length(LONGDESCRIPTION.LDTEXT) > 400 then '5. 400-500'
    when length(LONGDESCRIPTION.LDTEXT) > 300 then '4. 300-400'
    when length(LONGDESCRIPTION.LDTEXT) > 200 then '3. 200-300'
    when length(LONGDESCRIPTION.LDTEXT) > 100 then '2. 100-200'
    when length(LONGDESCRIPTION.LDTEXT) > 0 then '1. 0-100'
    else 'OTHER'
  end, sr.ticketid;

select *
from LONGDESCRIPTION
where LONGDESCRIPTION.LDOWNERCOL = 'FR2CODE'
  and LONGDESCRIPTION.LDOWNERTABLE = 'TICKET';

/*******************************************************************************
*  Count of incidents by failure details
*******************************************************************************/

select CLASSSTRUCTURE.CLASSSTRUCTUREID,
  case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid HIERARCHYPATH, count(*)
from INCIDENT
  join CLASSSTRUCTURE on INCIDENT.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
  left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
  left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
  left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
  left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid
group by CLASSSTRUCTURE.CLASSSTRUCTUREID,
  case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid
order by case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid;




select 
  CLASSSTRUCTURE.CLASSSTRUCTUREID,
  case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid HIERARCHYPATH,
  INCIDENT.FAILURECODE FAILURECLASS, FAILUREREPORT.TYPE, FAILUREREPORT.FAILURECODE, 
  count(*)
from FAILUREREPORT
  join INCIDENT on INCIDENT.TICKETID = FAILUREREPORT.TICKETID
  join CLASSSTRUCTURE on INCIDENT.CLASSSTRUCTUREID = CLASSSTRUCTURE.CLASSSTRUCTUREID
  left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
  left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
  left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
  left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid
where FAILUREREPORT.TICKETCLASS = 'INCIDENT'
group by 
  CLASSSTRUCTURE.CLASSSTRUCTUREID,
  case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid,
  INCIDENT.FAILURECODE, FAILUREREPORT.TYPE, FAILUREREPORT.FAILURECODE
order by 
  CLASSSTRUCTURE.CLASSSTRUCTUREID,
  case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
  case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
  case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
  case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
  Classstructure.Classificationid,
  INCIDENT.FAILURECODE, FAILUREREPORT.TYPE, FAILUREREPORT.FAILURECODE;