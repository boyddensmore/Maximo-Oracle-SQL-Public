-- REGEX to remove all HTML tags.
-- REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' ') LONG_DESCRIPTION

select 
  ticket.ticketid, Ticket.Status, ticket.reportdate, Ticket.Ownergroup, Ticket.Owner, 
  Ticket.Classificationid TK_CLASSIFICAITON, Classstructure.Description TK_CLASSIFICATION_DESC, 
  ticket.description TK_SUMMARY, REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' ') LONG_DESCRIPTION, 
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
  --and TICKET.REPORTDATE >= sysdate - 10
  -- Find instances of asset tags in Summary, Long Description, or Asset fields
  and (exists (select asset.ASSETTAG from asset where upper(asset.ex_model) LIKE '%SURFACE%' and LONGDESCRIPTION.LDTEXT like '%' || upper(ASSET.ASSETTAG) || '%')
    or exists (select asset.ASSETTAG from asset where upper(asset.ex_model) LIKE '%SURFACE%' and TICKET.DESCRIPTION like '%' || upper(ASSET.ASSETTAG) || '%')
    or TICKET.ASSETNUM in (select ASSET.ASSETNUM from asset where upper(asset.ex_model) LIKE '%SURFACE%'))
  and (upper(LONGDESCRIPTION.LDTEXT) like '%SURFACE%'
      or upper(ticket.description) like '%SURFACE%')
--  and (ticket.class = 'SR' or (ticket.class = 'INCIDENT' and ticket.Origrecordid is null))
  and ticket.class = 'INCIDENT'
  and TICKET.REPORTDATE >= TO_DATE('01-JUL-15 00:00:00', 'dd-MON-yy hh24:mi:ss')
order by ticketid;

