set define off;


-- 

-- The purpose of the query is to count the Maximo licenses assigned to each user.
-- Each user is assigned to a Core Maximo, Transportation, Utilites, Nuclear, HSE-Add on, Scheduler-Add on, Service Provider-Add on, System Users and Self Service Requestor-Free
-- The tables used for counting are:
--      The list of users (MAXUSER table) with the ACTIVE status
--      The security groups assigned to the users (GROUPUSER table),
--      The detail of the rights by group user (table APPLICATIONAUTH)
--      Applications / Modules (MAXMENU and MAXMODULES table)
--      The login history for each user (LOGINTRACKING table)
-- 
-- STEP 1 - Delete Orphan Records from Applicationauth Table
-- 
-- STEP 2 - Creating user records and licenses in the temporary table
--      Insert in a temporary table (licensemetric Table) all users and associated licenses
--      This table will check the total number of users declared in Maximo and the total number of users and associated licenses (temporary table)
-- STEP 3 - Publishing Reports
--      1 Count of the total number of users declared with the ACTIVE status
--      2 Users by type of license without Filter on dates
--      3 List of users and their associated license without Filter on dates
--      4 Users by type of license with at least 1 connection over the duration of the contract and summary table
--      5 List anonymously users with associated license type having at least 1 connection over the duration of the contract with their Creation Date, the Date of first login, the date of Last login 
--        date, the total number of login
--	6 Detailed user concurrent count from Logintracking current count attribute for the past 365 days
--	7 Distinct Users with successful logins from Logintracking for the past 365 days


Prompt *****************************************************************************************************************************;
Prompt Scheduler users : Insert Scheduler users in licensemetric table;
Prompt *****************************************************************************************************************************;

-- Scheduler
-- The user is entitled to access scheduler applications  
-- assigned to the Licensee.
-- Users must be active

SELECT distinct(maxuser.userid) , 'Scheduler'
FROM groupuser
INNER JOIN maxuser ON groupuser.userid = maxuser.userid

-- All rights on selected apps
INNER JOIN applicationauth ON groupuser.groupname = applicationauth.groupname
WHERE optionname IN ('INSERT')

-- Include only users with active status
AND maxuser.status IN (SELECT value FROM synonymdomain WHERE domainid = 'MAXUSERSTATUS' AND maxvalue = 'ACTIVE')
-- Exclude System Users
AND maxuser.sysuser != '1'
-- Only Scheduler Applications
AND app IN('SCHEDMAX','SCHEDACM','RLAASSIGN','RLCAPACITY'); 



Prompt *****************************************************************************************************************************;
Prompt Authorized MAM users : Insert Authorized MAM users in licensemetric table ;
Prompt *****************************************************************************************************************************;

-- Authorized MAM
-- The user can use more than three (3) Maximo Asset Management modules within the IBM Maximo Asset Management Software.
-- Maximo Full users: all users who have write access (SAVE) to applications related to the Core product and no application related to the Transportation industry solution where number of modules is 
-- greater than 3
-- Users must be active

SELECT userid, 'Premium' FROM (
SELECT userid, module  FROM (
SELECT maxuser.userid userid, maxmodules.module module
FROM maxuser
INNER JOIN groupuser ON groupuser.userid = maxuser.userid
INNER JOIN applicationauth ON groupuser.groupname = applicationauth.groupname
INNER JOIN maxmenu ON applicationauth.app=maxmenu.keyvalue
INNER JOIN maxmodules ON (elementtype = 'APP' and module = moduleapp)

-- All rights on selected apps
WHERE applicationauth.optionname = 'INSERT'
AND maxuser.status IN (SELECT value FROM synonymdomain WHERE domainid = 'MAXUSERSTATUS' AND maxvalue = 'ACTIVE')
-- Exclude System Users
AND maxuser.sysuser != '1'
AND applicationauth.app IN 
('ACTION','ACTIONSCFG','ACTIVITY','ACTUALCI','AMCREW','AMCREWT','ASSET','ASSETCAT','AUTOSCRIPT','BBOARD','CALENDR','CGRPASSIGN','CHANGE',
'CHRTACCT','CI','CITYPE','COGNOSHOME','COLLECTION','COMMTMPLT','COMPANY','COMPMASTER','COND','CONDCODE','CONDEXPMGR','CONFIGUR',
'CONTLABOR','CONTLEASE','CONTMASTER','CONTPURCH','CONTSFW','CONTWARRTY','CRAFT','CREATEINT','CRONTASK','CURRENCY','DEPLCOLLS','DEPLGROUPS','DESIGNER',
'DM','DOMAINADM','DPAMADPT','DPAMMANU','DPAMOS','DPAMPROC','DPAMSW','DPAMSWS','DPAMSWUSG','DPLDASSET','ECOMMADAPT','EMAILSTNER','ENDPOINT','ESCALATION',
'EXCHANGE','EXTSYSTEM','FACONFIG','FAILURE','FEATURE','FINCNTRL','FORGOTPSWD','GRPASSIGN','HAZARDS','IBMCONTENT','IM','IMICONF','INBXCONFIG','INCIDENT',
'INTERROR','INTMSGTRK','INTOBJECT','INTSRV','INVENTOR','INVISSUE','INVOICE','INVOKE','INVUSAGE','ITEM','JOBPLAN','JSONRES','KPI','KPIGCONFIG',
'KPILCONFIG','KPITPL','KPIVIEWER','LABOR','LABREP','LAUNCH','LICTRACK','LMO','LOCATION','LOGGING','MANAGEINT','MASTERPM','METER','METERGRP','MFMAILCFG',
'MOBDATAMAN','MOBERRHND','MOBILEAM','MOBILEINST','MOBILEINV','MOBILEWO','MPMAN','MULTISITE','NDASSET','NPASSET','OSLCPROV','OSLCRES','PERSON','PERSONGR',
'PM','PMCOMSR','PO','PR','PRECAUTN','PROBLEM','PROPMAINT','PUBLISH','QUAL','QUICKREP','RCNASTLINK','RCNASTRSLT','RCNCILINK','RCNCIRSLT','RCNCMPRULE',
'RCNLNKRULE','RCNTSKFLTR','RECEIPTS','RECONTASK','RELATION','RELEASE','REPLISTCFG','REPORT','RFQ','RLADMIN','RLASSIGN','RLCAPACITY','ROLE','ROUTES',
'RPTOUTPUT','RSCONFIG','SAFEPLAN','SCCONFIG','SCHSUPER','SECUGRPMOB','SECURGROUP','SELFREG','SETS','SFWLICVIEW','SHIPREC','SLA','SOLUTION','SR','SRVAD',
'SRVCOMMOD','SRVITEM','STARTCNTR','STOREROOM','TAGLOCKS','TECHLITE','TECHPHONE','TECHTABLET','TERMCOND','TKTEMPLATE','TLOAMSWCTG','TOOL','TOOLINV','USER',
'VIEWDOC','WFADMIN','WFDESIGN','WORKMAN','WORKVIEW','WORKZONE','WOTRACK','WSREGISTRY','PLUSGLOG','PLUSGLPROF','PLUSGMCR','PLUSGMOC','PLUSGOPACT',
'PLUSGOPTSK','PLUSGORG','PLUSGPCT','PLUSGPM','PLUSGPO','PLUSGPOL','PLUSGPR','PLUSGPREC','PLUSGPROC','PLUSGPRS','PLUSGPTW','PLUSGQRP','PLUSGQUAL','PLUSGREG',
'PLUSGRFW','PLUSGROU','PLUSGRSK','PLUSGSOL','PLUSGSR','PLUSGSR','PLUSGSTA','PLUSGSTAG','PLUSGTGLCK','PLUSGTKTMP','PLUSGVWINC','PLUSGWO')

--AND maxuser.userid IN (SELECT userid FROM maxuser where type = 'NOTYPE')

GROUP BY maxuser.userid, maxmodules.module, applicationauth.app)
GROUP BY userid, module)
GROUP BY userid
HAVING COUNT(*)>3;




Prompt *****************************************************************************************************************************;
Prompt Maximo Limited users : Insert Maximo Limited users in licensemetric table ;
Prompt *****************************************************************************************************************************;

-- MAM Limited
-- The user can not use more than three (3) Maximo Asset Management modules within the IBM Maximo Asset Management Software.
-- Maximo Limited users: all users who have write access (SAVE) to applications related to the Core product and to any application related to the Transportation industrial solution where number of modules is at most 3
-- Users must be active

SELECT  userid,'Limited MAM' FROM (
SELECT userid, module  FROM (
SELECT maxuser.userid userid, maxmodules.module module
FROM maxuser
INNER JOIN groupuser ON groupuser.userid = maxuser.userid
INNER JOIN applicationauth ON groupuser.groupname = applicationauth.groupname
INNER JOIN maxmenu ON applicationauth.app=maxmenu.keyvalue
INNER JOIN maxmodules ON (elementtype = 'APP' and module = moduleapp)
WHERE applicationauth.optionname = 'INSERT'
AND maxuser.status IN (SELECT value FROM synonymdomain WHERE domainid = 'MAXUSERSTATUS' AND maxvalue = 'ACTIVE')
AND maxuser.sysuser != '1'
AND applicationauth.app IN 
('ACTION','ACTIONSCFG','ACTIVITY','ACTUALCI','AMCREW','AMCREWT','ASSET','ASSETCAT','AUTOSCRIPT','BBOARD','CALENDR','CGRPASSIGN',
'CHANGE','CHRTACCT','CI','CITYPE','COGNOSHOME','COLLECTION','COMMTMPLT','COMPANY','COMPMASTER','COND','CONDCODE','CONDEXPMGR',
'CONFIGUR','CONTLABOR','CONTLEASE','CONTMASTER','CONTPURCH','CONTSFW','CONTWARRTY','CRAFT','CREATEINT','CRONTASK',
'CURRENCY','DEPLCOLLS','DEPLGROUPS','DESIGNER','DM','DOMAINADM','DPAMADPT','DPAMMANU','DPAMOS','DPAMPROC','DPAMSW','DPAMSWS','DPAMSWUSG',
'DPLDASSET','ECOMMADAPT','EMAILSTNER','ENDPOINT','ESCALATION','EXCHANGE','EXTSYSTEM','FACONFIG','FAILURE','FEATURE','FINCNTRL','FORGOTPSWD',
'GRPASSIGN','HAZARDS','IBMCONTENT','IM','IMICONF','INBXCONFIG','INCIDENT','INTERROR','INTMSGTRK','INTOBJECT','INTSRV','INVENTOR','INVISSUE',
'INVOICE','INVOKE','INVUSAGE','ITEM','JOBPLAN','JSONRES','KPI','KPIGCONFIG','KPILCONFIG','KPITPL','KPIVIEWER','LABOR','LABREP','LAUNCH',
'LICTRACK','LMO','LOCATION','LOGGING','MANAGEINT','MASTERPM','METER','METERGRP','MFMAILCFG','MOBDATAMAN','MOBERRHND','MOBILEAM','MOBILEINST',
'MOBILEINV','MOBILEWO','MPMAN','MULTISITE','NDASSET','NPASSET','OSLCPROV','OSLCRES','PERSON','PERSONGR','PM','PMCOMSR','PO','PR','PRECAUTN','PROBLEM','PROPMAINT','PUBLISH','QUAL','QUICKREP','RCNASTLINK','RCNASTRSLT','RCNCILINK','RCNCIRSLT',
'RCNCMPRULE','RCNLNKRULE','RCNTSKFLTR','RECEIPTS','RECONTASK','RELATION','RELEASE','REPLISTCFG','REPORT','RFQ','RLADMIN','RLASSIGN','RLCAPACITY','ROLE','ROUTES',
'RPTOUTPUT','RSCONFIG','SAFEPLAN','SCCONFIG','SCHSUPER','SECUGRPMOB','SECURGROUP','SELFREG','SETS','SFWLICVIEW','SHIPREC','SLA','SOLUTION',
'SR','SRVAD','SRVCOMMOD','SRVITEM','STARTCNTR','STOREROOM','TAGLOCKS','TECHLITE','TECHPHONE','TECHTABLET','TERMCOND','TKTEMPLATE','TLOAMSWCTG','TOOL','TOOLINV','USER',
'VIEWDOC','VIEWDRFT','VIEWTMPL','WFADMIN','WFDESIGN','WORKMAN','WORKVIEW','WORKZONE','WOTRACK','WSREGISTRY','PLUSGLOG','PLUSGLPROF','PLUSGMCR','PLUSGMOC','PLUSGOPACT','PLUSGOPTSK','PLUSGORG','PLUSGPCT','PLUSGPM','PLUSGPO','PLUSGPOL','PLUSGPR','PLUSGPREC','PLUSGPROC','PLUSGPRS',
'PLUSGPTW','PLUSGQRP','PLUSGQUAL','PLUSGREG','PLUSGRFW','PLUSGROU','PLUSGRSK','PLUSGSOL','PLUSGSR','PLUSGSR','PLUSGSTA','PLUSGSTAG','PLUSGTGLCK','PLUSGTKTMP','PLUSGVWINC','PLUSGWO')

--AND maxuser.userid IN (SELECT userid FROM maxuser where type = 'NOTYPE')
GROUP BY maxuser.userid, maxmodules.module, applicationauth.app)
GROUP BY userid, module)
GROUP BY userid
HAVING COUNT(*)<=3;

Prompt *****************************************************************************************************************************;
Prompt Maximo Free users : Insert Maximo No License Needed in licensemetric table ;
Prompt *****************************************************************************************************************************;

SELECT distinct(maxuser.userid) , 'No License Needed'
FROM groupuser
INNER JOIN maxuser ON groupuser.userid = maxuser.userid

-- All rights on selected apps
INNER JOIN applicationauth ON groupuser.groupname = applicationauth.groupname
WHERE optionname IN ('INSERT')

-- Include only users with active status
AND maxuser.status IN (SELECT value FROM synonymdomain WHERE domainid = 'MAXUSERSTATUS' AND maxvalue = 'ACTIVE')
-- Exclude System Users
AND maxuser.sysuser != '1'
-- Only Self Service Applications
AND app IN('CREATESR','CREATEDR','VIEWSR','VIEWDR','VIEWDRAFT','VIEWTMPL','SEARCHSOL')
--AND maxuser.userid IN (SELECT userid FROM maxuser where type = 'NOTYPE')
;



-- Remark this section out when Oil and Gas is installed
Prompt *****************************************************************************************************************************;
Prompt HSE users : Insert HSE users in licensemetric table ;
Prompt *****************************************************************************************************************************;


-- HSE
-- The user is entitle to access calibration applications
-- Assigned to the Licensee.
-- Users must be active
SELECT * FROM maxuser WHERE status = 'ACTIVE' AND sysuser != '1' and userid in (SELECT distinct(maxuser.userid) FROM (
    SELECT userid, module  FROM (
    SELECT maxuser.userid userid, maxmodules.module module
    FROM maxuser
    INNER JOIN groupuser ON groupuser.userid = maxuser.userid
    INNER JOIN applicationauth ON groupuser.groupname = applicationauth.groupname
    INNER JOIN maxmenu ON applicationauth.app=maxmenu.keyvalue
    INNER JOIN maxmodules ON (elementtype = 'APP' and module = moduleapp)
    WHERE applicationauth.optionname = 'INSERT'
    AND applicationauth.app IN 
    ('PLUSGLOG','PLUSGLPROF','PLUSGMCR','PLUSGMOC','PLUSGOPACT','PLUSGOPTSK','PLUSGORG','PLUSGPCT','PLUSGPM','PLUSGPO','PLUSGPOL','PLUSGPR','PLUSGPREC','PLUSGPROC','PLUSGPRS',
    'PLUSGPTW','PLUSGQRP','PLUSGQUAL','PLUSGREG','PLUSGRFW','PLUSGROU','PLUSGRSK','PLUSGSOL','PLUSGSR','PLUSGSR','PLUSGSTA','PLUSGSTAG','PLUSGTGLCK','PLUSGTKTMP','PLUSGVWINC','PLUSGWO')
    AND maxuser.userid IN (SELECT userid FROM maxuser where type = 'NOTYPE')
    GROUP BY maxuser.userid, maxmodules.module, applicationauth.app)
    GROUP BY userid, module)
    GROUP BY userid
    HAVING COUNT(*)>3);

