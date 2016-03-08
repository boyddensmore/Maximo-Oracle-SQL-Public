/*******************************************************************************
*  Example, find second lowest TKOWNERHISTORYID for a given ticket
*******************************************************************************/

SELECT TKOWNERHISTORYID
  FROM (SELECT TKOWNERHISTORYID,
               dense_rank() over (order by TKOWNERHISTORYID asc) rnk
          FROM TKOWNERHISTORY
          where ticketid = 'IN-6974')
 WHERE rnk = 2;