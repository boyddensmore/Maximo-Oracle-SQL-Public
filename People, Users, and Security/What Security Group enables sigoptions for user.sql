
/*******************************************************************************
*  Query to determine what security group is granting a user sigoptions
*******************************************************************************/

SELECT 
  groupuser.userid,
  maxgroup.groupname,
  ',=' || maxgroup.groupname,
  sigoption.app,
  sigoption.description sigoptiondesc,
  applicationauth.CONDITIONNUM
FROM groupuser
  left JOIN maxgroup ON maxgroup.groupname=groupuser.groupname
  left JOIN applicationauth ON applicationauth.groupname=maxgroup.groupname
  left JOIN sigoption ON sigoption.optionname=applicationauth.optionname AND sigoption.app=applicationauth.app
WHERE 1=1
--  and groupuser.userid='SSHANNON'
  and maxgroup.groupname in ('CHGANL')
  and SIGOPTION.APP = 'CHANGE'
--  and SIGOPTION.DESCRIPTION = 'Change Status'
--  and upper(SIGOPTION.DESCRIPTION) = 'PMTCOCHATQ'
--  and SIGOPTION.DESCRIPTION = 'Change Status'
ORDER BY groupuser.userid, APPLICATIONAUTH.APP, APPLICATIONAUTH.GROUPNAME, SIGOPTION.DESCRIPTION;



/*******************************************************************************
*  List all sigoptions granted to security groups
*******************************************************************************/

SELECT
  maxapps.app,
  maxapps.description,
  maxgroup.groupname,
  maxgroup.description GROUPDESC,
  APPLICATIONAUTH.OPTIONNAME SIGOPTION_GRANTED,
  (select count(*) from groupuser where groupname = maxgroup.groupname) USER_COUNT
FROM maxapps
  join applicationauth on applicationauth.app = maxapps.app
  join maxgroup on MAXGROUP.GROUPNAME = APPLICATIONAUTH.GROUPNAME
where maxapps.app in ('CHANGE')
-- and maxgroup.groupname in ('CHGANL')
 and APPLICATIONAUTH.OPTIONNAME in ('STATUS')
ORDER BY maxapps.app, maxgroup.groupname;


/*******************************************************************************
*  Show security group permissions by app and security group
*******************************************************************************/

SELECT
  maxapps.app,
  maxapps.description,
  maxgroup.groupname,
  ',=' ||maxgroup.groupname,
  maxgroup.description,
  (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='READ') appread,
  (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='SAVE') appsave,
  (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='INSERT') appins,
  (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='DELETE') appdel,
  (SELECT COUNT(*) FROM GROUPUSER JOIN PERSON ON PERSON.PERSONID = GROUPUSER.USERID AND STATUS = 'ACTIVE' WHERE groupname=maxgroup.groupname) GROUPUSERS
FROM maxapps, maxgroup
WHERE 1=1
  and maxapps.app = 'CHANGE'
--  and maxgroup.groupname != 'SERVICE DESK'

    -- All permissions
--  and (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='READ') > 0
--  and (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='SAVE') > 0
--  and (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='INSERT') > 0
--  and (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='DELETE') > 0

    -- Any permissions
  and ((SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='READ') > 0
  or (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='SAVE') > 0
  or (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='INSERT') > 0
  or (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='DELETE') > 0)


  and (SELECT COUNT(*) FROM GROUPUSER JOIN PERSON ON PERSON.PERSONID = GROUPUSER.USERID AND STATUS = 'ACTIVE' WHERE groupname=maxgroup.groupname) > 0
--ORDER BY maxapps.app, maxgroup.groupname
;


SELECT
  maxapps.app,
  maxapps.description,
  maxgroup.groupname,
  ',=' ||maxgroup.groupname,
  maxgroup.description,
  (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='READ') appread,
  (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='SAVE') appsave,
  (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='INSERT') appins,
  (SELECT COUNT(*) FROM applicationauth WHERE groupname=maxgroup.groupname AND app=maxapps.app AND optionname='DELETE') appdel,
  (SELECT COUNT(*) FROM GROUPUSER JOIN PERSON ON PERSON.PERSONID = GROUPUSER.USERID AND STATUS = 'ACTIVE' WHERE groupname=maxgroup.groupname) GROUPUSERS
FROM maxapps, maxgroup
WHERE 1=1
  and maxapps.app = 'CHANGE'
;

