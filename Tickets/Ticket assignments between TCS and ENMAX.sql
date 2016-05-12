/*******************************************************************************
*  Testing - Show all owner history for single ticket
*******************************************************************************/

select tkownerhistory.ticketid, tkownerhistory.class, tkownerhistory.ownergroup, 
  tkownerhistory.owner, tkownerhistory.owndate, 
  tkownerhistory.ownerchangeby, tkownerhistory.Assignedownergroup, 
  assigned_group.Ex_Manager
from tkownerhistory
  left join persongroup assigned_group on Tkownerhistory.Assignedownergroup = assigned_group.Persongroup
  left join persongroup ownergroup on Tkownerhistory.Ownergroup = Ownergroup.Persongroup
where Tkownerhistory.Assignedownergroup = 'SERVICE DESK'
order by Tkownerhistory.Ticketid;


/*******************************************************************************
*  Count of assignments to ENMAX and to TCS for each ticket that has been
*  assigned to TCS at least once
*******************************************************************************/

select ticket.ticketid, Tcs_Assignments.Assigned_To_Tcs_Count, Enmax_Assignments.Assigned_To_Enmax_Count
from ticket
  join 
  (select tkownerhistory.ticketid, count(*) ASSIGNED_TO_TCS_COUNT
    from tkownerhistory
      left join persongroup assigned_group on Tkownerhistory.Assignedownergroup = assigned_group.Persongroup
    where 
    -- Ticket was assigned to TCS
      assigned_group.ex_manager = '[[USERID]]'
    group by tkownerhistory.ticketid) Tcs_Assignments on Tcs_Assignments.Ticketid = Ticket.Ticketid
  left join
  (select tkownerhistory.ticketid, count(*) ASSIGNED_TO_ENMAX_COUNT
    from tkownerhistory
      left join persongroup assigned_group on Tkownerhistory.Assignedownergroup = assigned_group.Persongroup
    where 
    -- Ticket was assigned to TCS
      assigned_group.ex_manager != '[[USERID]]'
    group by tkownerhistory.ticketid) Enmax_Assignments on Enmax_Assignments.Ticketid = Ticket.Ticketid
and Ticket.Creationdate >= to_date('01-01-2015', 'mm-dd-yyyy');



/*******************************************************************************
*  Count of assignments to ENMAX and to TCS for each ticket that has been
*  assigned to both ENMAX and TCS at least once
*******************************************************************************/

select ticket.ticketid, Tcs_Assignments.Assigned_To_Tcs_Count, Enmax_Assignments.Assigned_To_Enmax_Count
from ticket
  join 
  (select tkownerhistory.ticketid, count(*) ASSIGNED_TO_TCS_COUNT
    from tkownerhistory
      left join persongroup assigned_group on Tkownerhistory.Assignedownergroup = assigned_group.Persongroup
    where 
    -- Ticket was assigned to TCS
      assigned_group.ex_manager = '[[USERID]]'
    group by tkownerhistory.ticketid) Tcs_Assignments on Tcs_Assignments.Ticketid = Ticket.Ticketid
  join
  (select tkownerhistory.ticketid, count(*) ASSIGNED_TO_ENMAX_COUNT
    from tkownerhistory
      left join persongroup assigned_group on Tkownerhistory.Assignedownergroup = assigned_group.Persongroup
    where 
    -- Ticket was assigned to TCS
      assigned_group.ex_manager != '[[USERID]]'
    group by tkownerhistory.ticketid) Enmax_Assignments on Enmax_Assignments.Ticketid = Ticket.Ticketid
and Ticket.Creationdate >= to_date('01-01-2015', 'mm-dd-yyyy');



/*******************************************************************************
* List of people not reporting to Renga
*******************************************************************************/

select Persongroupteam.Respparty 
from persongroupteam
  join persongroup on persongroupteam.persongroup = Persongroup.Persongroup
where Persongroup.Ex_Manager != '[[USERID]]';



/*******************************************************************************
*  Count of tickets that have been assigned to TCS at least once
*******************************************************************************/

select count(distinct(Tkownerhistory.ticketid)) DISTINCT_TCS_TICKETS
from tkownerhistory
  left join persongroup assigned_group on Tkownerhistory.Assignedownergroup = assigned_group.Persongroup
where assigned_group.ex_manager = '[[USERID]]'
order by Tkownerhistory.Ticketid