select *
from report
where LASTRUNBY = 'BDENSMOR';



/*******************************************************************************
*  Report Details
*******************************************************************************/

select REPORT.REPORTNAME, REPORT.LASTRUNBY, REPORT.LASTRUNDATE, REPORT.DESCRIPTION, 
  REPORTLOOKUP.PARAMETERNAME, REPORTLOOKUP.LABELOVERRIDE PARAMETER_DESC,
  REPORTDESIGN.DESIGN
from reportdesign
  join report on REPORTDESIGN.REPORTNAME = REPORT.REPORTNAME
  left join REPORTLOOKUP on REPORTLOOKUP.REPORTNAME = REPORTDESIGN.REPORTNAME
where 1=1
  and upper(REPORTDESIGN.DESCRIPTION) like '%BACKLOG%'
--  and REPORT.LASTRUNDATE is not null
order by REPORT.LASTRUNDATE desc;


select *
from REPORTSCHED;

select *
from REPORTUSAGELOG
where upper(reportname) like '%BACKLOG%'
;