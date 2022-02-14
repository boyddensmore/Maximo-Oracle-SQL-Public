
/*******************************************************************************
* Query to determine what security group is granting a user sigoptions.
* Only granted sigoptions are returned.
* Author: Boyd Densmore, 2017
*******************************************************************************/



SELECT 
  distinct 
  sigoption.app,
--  maxgroup.groupname,
  ',=' || maxgroup.groupname,
--  sigoption.description sigoptiondesc,
  listagg(SIGOPTION.optionname, ', ') within group (order by sigoption.app, maxgroup.groupname) PERMISSIONS
--  ,
--  applicationauth.CONDITIONNUM
FROM maxgroup
  left JOIN applicationauth ON applicationauth.groupname=maxgroup.groupname
  left JOIN sigoption ON sigoption.optionname=applicationauth.optionname AND sigoption.app=applicationauth.app
WHERE 1=1
--  and groupuser.userid  not in ('AUTOGEN', 'MAXADMIN', 'MXINTADM')
--  and maxgroup.groupname in ('ENGINEER_CE', 'ENGINEER_SCE', 'ENGSUPT')
  and SIGOPTION.APP like 'STARTCNTR'
--  and SIGOPTION.optionname in ('READ', 'SAVE', 'INSERT', 'DELETE')
  and upper(SIGOPTION.DESCRIPTION) like '%LAUNCH%'
--  and SIGOPTION.DESCRIPTION like 'BCF PR Line can' || chr(39) || 't have item info edited unless Inventory Save Access'
--  and SIGOPTION.DESCRIPTION like 'Launch BCF Meter app'
group by sigoption.app, 
    maxgroup.groupname
order by sigoption.app, 
--    maxgroup.groupname
  ',=' || maxgroup.groupname
;

select *
from applicationauth
where optionname = 'BCFPRLINEREADONLYITEMS';
/*******************************************************************************
*  List all sigoptions
*******************************************************************************/

SELECT
  maxapps.app,
  maxapps.description,
  maxgroup.groupname,
  maxgroup.description,
  CURSOR (SELECT optionname FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app) AS auth
FROM maxapps, maxgroup
--where app = 'PERSON'
where groupname = 'EX_ITIS'
ORDER BY maxapps.app, maxgroup.groupname;


/*******************************************************************************
*  Show security group permissions by app and security group
*******************************************************************************/

select *
from maxapps
where description like 'Sound%';

SELECT
  maxapps.app,
  maxapps.description,
  maxgroup.groupname,
--  ',=' ||maxgroup.groupname,
  maxgroup.description,
  (SELECT COUNT(*) FROM maximo.applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='READ') appread,
  (SELECT COUNT(*) FROM maximo.applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='SAVE') appsave,
  (SELECT COUNT(*) FROM maximo.applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='INSERT') appins,
  (SELECT COUNT(*) FROM maximo.applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='DELETE') appdel,
  (SELECT COUNT(*) FROM maximo.GROUPUSER JOIN maximo.PERSON ON PERSON.PERSONID = GROUPUSER.USERID AND STATUS = 'ACTIVE' WHERE groupname=maxgroup.groupname) GROUPUSERS
FROM maximo.maxapps, maximo.maxgroup
WHERE 1=1
  and maxapps.app in ('COND')
--  and maxapps.app like 'PR%'
--  and maxapps.description like ('Preventive%')
--  and maxgroup.groupname not in ('TECHTEAM', 'MAXADMIN', 'CMMS_ADMIN')
--  and maxgroup.groupname like '%ENG%' 

    -- All permissions
--  and (SELECT COUNT(*) FROM maximo.applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='READ') > 0
--  and (SELECT COUNT(*) FROM maximo.applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='SAVE') > 0
--  and (SELECT COUNT(*) FROM maximo.applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='INSERT') > 0
--  and (SELECT COUNT(*) FROM maximo.applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='DELETE') > 0

    -- Any permissions
  and ((SELECT COUNT(*) FROM maximo.applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='READ') > 0
  or (SELECT COUNT(*) FROM maximo.applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='SAVE') > 0
  or (SELECT COUNT(*) FROM maximo.applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='INSERT') > 0
  or (SELECT COUNT(*) FROM maximo.applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='DELETE') > 0)


  and (SELECT COUNT(*) FROM maximo.GROUPUSER JOIN maximo.PERSON ON PERSON.PERSONID = GROUPUSER.USERID AND STATUS = 'ACTIVE' WHERE groupname=maxgroup.groupname) > 0
--ORDER BY maxapps.app, maxgroup.groupname
;



