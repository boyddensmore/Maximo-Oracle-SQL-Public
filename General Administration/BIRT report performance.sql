SELECT AVG(enddate-startdate)*24*60, reportname
FROM reportusagelog
GROUP BY reportname
ORDER BY AVG(enddate-startdate) DESC