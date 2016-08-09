/*******************************************************************************
*  Set current connection schema to MAXIMO for report simplicity
*******************************************************************************/
alter session set current_schema = MAXIMO;


/*******************************************************************************
*  Show spec changes in the past 14 days
*******************************************************************************/

select assetnum, ASSETATTRID, ALNVALUE, PERSON.DISPLAYNAME, CHANGEDATE, CREATEDDATE, REMOVEDDATE
from ASSETSPECHIST
  left join PERSON on PERSON.PERSONID = ASSETSPECHIST.CHANGEBY
where (CHANGEDATE >= sysdate - 7 or CREATEDDATE >= sysdate - 7 or REMOVEDDATE >= sysdate - 7)
order by ASSETNUM, ASSETATTRID, CHANGEDATE;