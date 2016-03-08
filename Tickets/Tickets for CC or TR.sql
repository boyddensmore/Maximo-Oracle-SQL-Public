-- REGEX to remove all HTML tags.
-- REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' ') LONG_DESCRIPTION

select 
--*
  ticket.ticketid, Ticket.Status, ticket.reportdate, Ticket.Ownergroup, Ticket.Owner, 
  Ticket.Classificationid TK_CLASSIFICAITON, Classstructure.Description TK_CLASSIFICATION_DESC, 
  ticket.description SUMMARY, REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' ') LONG_DESCRIPTION, 
  Asset.Assettag, Assetclass.Description asset_class, Ci.Ciname, ciclass.Description ci_class, Person.Displayname AFF_PERSON_NAME, person.company AFF_PERSON_COMPANY, Person.Department AFF_PERSON_DEPT, 
  Person.Deptdesc AFF_PERSON_DEPT_DESC

from ticket
  join person on PERSON.PERSONID = TICKET.AFFECTEDPERSON
  left join asset on Ticket.Assetnum = asset.assetnum
  left join CI on Ticket.Cinum = ci.cinum
  join Longdescription on Longdescription.ldkey = Ticket.Ticketuid
  join classstructure on Classstructure.Classstructureid = Ticket.Classstructureid
  left join classstructure assetclass on Assetclass.Classstructureid = Asset.Classstructureid
  left join classstructure ciclass on ciclass.Classstructureid = Ci.Classstructureid
where Longdescription.Ldownertable = 'TICKET'
  and Longdescription.LDOWNERCOL = 'DESCRIPTION'
and (ticket.class = 'SR' or (ticket.class = 'INCIDENT' and Ticket.Origrecordid is null))
and (person.department in ('43200', '43230') 
or Ticket.Affectedperson in ('BLAWRENC', 'RPARK', 'DSAKAI', 'KPOXON', 'KSHORT', 'CSHIRRIF', 'NPOPOVIC', 'GNOLAN', 'GNIXON', 'BPODESKY', 'TPATTON', 'HSHUKYS', 'AZEILER', 'RWILLIA2', 'GZIEBERT', 'RZIBELL', 'VTYCHOLI', 'TSTANKO', 'SSMITH', 'WTHIESSE', 'BSULLIVA', 'DMURASKI', 'KHESCH', 'RGREIR', 'GHOW', 'EHOFER', 'RDYER', 'JANDERSO', 'WADAIR', 'RDRAKE', 'JCHAPIN', 'RJAMES', 'RMCEACHE', 'DMCCASKI', 'RMCEVOY', 'TMAMRAK', 'EKEMPIN', 'MKAYSER', 'RLECAPPE', 'MKNIGHT', 'RJMCNEIL', 'TONSLOW', 'DOSNESS', 'MPARRILL', 'CMANCHES', 'BMCKAY', 'JMETKA', 'CPORTH', 'MSTEVENS', 'WMAGERA', 'RDAUK', 'MDELONG', 'DESSAY', 'CBRONSON', 'BBROWN', 'MICOOPER', 'SEVANS', 'THATTER', 'BHRYHORI', 'RMAEKELB', 'NGILCHRI', 'EHAMILTO', 'THASSELB', 'LMSIMONE', 'AKHAKOO', 'RREALUBI', 'GTONER', 'LVINCENT'));



/*******************************************************************************
*  HW/SW procurement tickets
*******************************************************************************/

select 
  ticket.ticketid, Ticket.Status, ticket.reportdate, Ticket.Ownergroup, Ticket.Owner, 
  Ticket.Classificationid TK_CLASSIFICAITON, Classstructure.Description TK_CLASSIFICATION_DESC, 
  ticket.description SUMMARY, REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' ') LONG_DESCRIPTION, 
  Asset.Assettag, Assetclass.Description asset_class, Ci.Ciname, ciclass.Description ci_class, Person.Displayname AFF_PERSON_NAME, person.company AFF_PERSON_COMPANY, Person.Department AFF_PERSON_DEPT, 
  Person.Deptdesc AFF_PERSON_DEPT_DESC
from ticket
  join person on PERSON.PERSONID = TICKET.AFFECTEDPERSON
  left join asset on Ticket.Assetnum = asset.assetnum
  left join CI on Ticket.Cinum = ci.cinum
  join Longdescription on Longdescription.ldkey = Ticket.Ticketuid
  join classstructure on Classstructure.Classstructureid = Ticket.Classstructureid
  left join classstructure assetclass on Assetclass.Classstructureid = Asset.Classstructureid
  left join classstructure ciclass on ciclass.Classstructureid = Ci.Classstructureid
where Longdescription.Ldownertable = 'TICKET'
  and Longdescription.LDOWNERCOL = 'DESCRIPTION'
  and (ticket.class = 'SR' or (ticket.class = 'INCIDENT' and Ticket.Origrecordid is null))
  and (EXTERNALSYSTEM_TICKETID = '10000'
  or EXTERNALSYSTEM = 'PROCUREPORTAL')
  and reportdate >= sysdate - 120
;