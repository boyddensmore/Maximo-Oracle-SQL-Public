select unique app
from applicationauth
where (optionname='READ' or optionname='SAVE' or optionname='DELETE' or optionname='INSERT') 
  and groupname in (select groupuser.groupname from groupuser where userid='[[USERID]]' )
  and (groupname not in (select varvalue from maxvars where varname='ALLUSERGROUP') 
  and app not in ('PLUSCTMPLT','PLUSTCLAIM','PLUSTCNTMP','PLUSTCOMP','PLUSTCONST','PLUSTCOUNT','PLUSTDTIMP','PLUSTINSP','PLUSTLOGS','PLUSTPOS','PLUSTRS','PLUSTSTKRG','PLUSTTLMCD','PLUSTTMPLT','PLUSTVEND','PLUSTVS','CHANGEPWD','CONTSFW','RPTOUTPUT','SFWLICVIEW','STARTCNTR','TLOAMSWCTG','PLUSPRESP')) 
  and not exists (select 1 from maxlicapps where licensenum='1005' and maxlicapps.appname= applicationauth.app);
