select Sr.Ticketid, Sr.Classificationid, Sr.Ownergroup, Sr.Owner, Sr.Description, Ci.Ciname, Ci.Pmcciimpact
from sr
left join ci on Sr.Cinum = Ci.Cinum
where sr.reportdate >= TO_TIMESTAMP ('2015-01-01 00:00:01.000' , 'YYYY-MM-DD HH24:MI:SS.FF')
and sr.reportdate <= TO_TIMESTAMP ('2015-01-31 23:59:59.000' , 'YYYY-MM-DD HH24:MI:SS.FF') 
and Sr.Classificationid = 'ENHANCE'
order by CI.PMCCIIMPACT;
--and ci.pmcciimpact = '1';