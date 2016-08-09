
-- List database objects

select
  servicename, objectname, classname, description,
  persistent, entityname, extendsobject, siteorgtype, userdefined, mainobject, internal, eauditenabled, eauditfilter, esigfilter
from maxobject
order by servicename, objectname;

-- List database objects and attributes

select
  objectname, attributeno, attributename,
  alias, autokeyname, canautonum, classname, columnname,
  complexexpression, defaultvalue, domainid, entityname,
  handlecolumnname, isldowner, ispositive, length, localizable,
  maxtype, mlinuse, mlsupported, mustbe, persistent,
  primarykeycolseq, remarks, required, restricted,
  sameasattribute, sameasobject, scale, searchtype,
  textdirection, title, userdefined, eauditenabled, esigenabled
from maxattribute
order by objectname, attributeno, attributename;



-- List applications

select app, apptype, custapptype, description,
  maintbname, orderby, originalapp, restrictions
from maxapps
order by app;


-- Generate hashes of app presentations so you can compare across environments.
 
 select
 sys_context('userenv','db_name') INSTANCE,
  m.app, m.apptype, m.custapptype, m.description,
  m.maintbname, m.orderby, m.originalapp, m.restrictions,
  ora_hash(mp.presentation) APP_HASH
from maxapps m
join maxpresentation mp on mp.app=m.app
order by m.app;


-- List reports

select
  reportfolder, appname, basetablename, reportname, runtype,
  description, scheduleonly, norequestpage, detail,
  toolbarlocation, toolbaricon, toolbarsequence, destinationfolder
from report
order by reportfolder, appname, reportname;


 -- Generate hashes of reports so you can compare across environments.
 
 select
  r.reportfolder, r.appname, r.basetablename, r.reportname, r.runtype, r.description,
  r.scheduleonly, r.norequestpage, r.detail, r.toolbarlocation,
  r.toolbaricon, r.toolbarsequence, r.destinationfolder,
  ora_hash(rd.design)
from report r
join reportdesign rd on rd.reportname=r.reportname;
order by reportfolder, appname, reportname;



-- List menus

select 
  menutype, moduleapp, position, subposition, visible, elementtype,
  keyvalue, headerdescription, image, tabdisplay, accesskey, url
from maxmenu
order by menutype, moduleapp, position, subposition;