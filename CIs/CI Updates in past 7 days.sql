/*******************************************************************************
*  Show CI update details from past 7 days
*******************************************************************************/
select Ci.Cinum, Ci.Ciname, Classstructure.Description, Ci.Status, Ci.Changeby , Ci.Changedate, Ci.RFC
from ci
join Classstructure on Classstructure.Classstructureid = Ci.Classstructureid
where Ci.changedate >= sysdate - 7
and Ci.changeby not in ('BDENSMOR', 'MXINTADM');