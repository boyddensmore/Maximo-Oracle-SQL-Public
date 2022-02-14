select reportname, design, to_char(substr(design, regexp_instr(design, 'like\s+''CEN', 1, 1, 0, 'i') - 20, 60))
from maximo.REPORTDESIGN
where REGEXP_LIKE(design, 'like\s+''CEN', 'i')
--and EXISTS (SELECT 1 FROM maximo.REPORTUSAGELOG WHERE REPORTUSAGELOG.reportname = reportdesign.reportname)

;