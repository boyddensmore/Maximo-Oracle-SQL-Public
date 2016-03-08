
/*******************************************************************************
*  Swap a person's first and last names from DISPLAYNAME
*******************************************************************************/

SELECT PERSONID,
  DISPLAYNAME,
  REGEXP_REPLACE(DISPLAYNAME,'(.*)(, *)(.*)','\3 \1')
FROM MAXIMO.PERSON
WHERE STATUS = 'ACTIVE';


/*******************************************************************************
*  Separate colon separated digits
*******************************************************************************/

select ticketid, CHANGEDATE, TKSTATUSID, STATUSTRACKING,
  REGEXP_REPLACE(STATUSTRACKING,'(\d*)(:)(\d*)(:)(\d*)','\1') STATUSTRACK_HOURS,
  REGEXP_REPLACE(STATUSTRACKING,'(\d*)(:)(\d*)(:)(\d*)','\3') STATUSTRACK_MINUTES,
  REGEXP_REPLACE(STATUSTRACKING,'(\d*)(:)(\d*)(:)(\d*)','\5') STATUSTRACK_SECONDS
from TKSTATUS
where STATUS = 'SLAHOLD'
--group by ticketid
order by ticketid;