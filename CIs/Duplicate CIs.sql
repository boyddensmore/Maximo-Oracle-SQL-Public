select ciname, count(cinum)
from ci
group by ciname
order by count(cinum) desc;