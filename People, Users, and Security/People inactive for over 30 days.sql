/*******************************************************************************
*  People in PENDING_DEACTIV status with ACTIVE user records
*******************************************************************************/

select ',=' || userid, userid, person.status PERSON_STATUS, maxuser.status USER_STATUS
from maxuser
  join person on person.personid = maxuser.userid
where person.status = 'PEND_DEACTIV'
  and MAXUSER.STATUS = 'ACTIVE'
  and exists (select EXIFACE_WDAYPERSON.personid, EXIFACE_WDAYPERSON.status, EXIFACE_WDAYPERSON.ex_transdatetime
              from MAXIMO.EXIFACE_WDAYPERSON
              where EXIFACE_WDAYPERSON.status != 'PEND_DEACTIV'
                and EXIFACE_WDAYPERSON.EX_TRANSDATETIME <= sysdate - 30
                and EXIFACE_WDAYPERSON.personid = person.personid);



/*******************************************************************************
*  When was a user last active in Workday?
*******************************************************************************/

select personid, status, EX_TRANSDATETIME
from MAXIMO.EXIFACE_WDAYPERSON
where personid = upper('[[USERNAME]]')
order by EX_TRANSDATETIME desc;