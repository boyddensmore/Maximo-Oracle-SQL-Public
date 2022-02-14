SELECT AVG(enddate-startdate)*24*60, reportname
FROM reportusagelog
GROUP BY reportname
ORDER BY AVG(enddate-startdate) DESC

select 'select * from ' || table_name || ';'
from all_tables
where table_name like '%REP%';

select * from REPORTBROS;

select *
from reportdesign
where design like '%dataSet_matusetrans%';