-- Unicode characters should be removed, as we can’t search for them in Maximo.
-- This SQL takes the Description for each Item and compares its length to the string 
--  length when Unicode characters are converted to ASCII

select itemnum, description, asciistr(description)
from maximo.item
where length(asciistr(description))!=length(description)  
order by description;