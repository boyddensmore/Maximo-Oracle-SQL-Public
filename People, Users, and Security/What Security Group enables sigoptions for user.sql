
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
  and groupuser.userid='SSHANNON'
  and maxgroup.groupname in ('CHGANL')
  and SIGOPTION.APP = 'CHANGE'
--  and upper(SIGOPTION.DESCRIPTION) = 'PMTCOCHATQ'
--  and SIGOPTION.DESCRIPTION = 'Change Status'
ORDER BY groupuser.userid, APPLICATIONAUTH.APP, APPLICATIONAUTH.GROUPNAME, SIGOPTION.DESCRIPTION;


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

select *
from groupuser
where groupname = 'CHGANL'
  and userid in ('SSHANNON', 'BDENSMOR');