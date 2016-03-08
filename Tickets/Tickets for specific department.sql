-- REGEX to remove all HTML tags.
-- REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' ') LONG_DESCRIPTION

select 
--*
ticket.ticketid, Ticket.Reportdate, ticket.class, ticket.owner, ticket.ownergroup, ticket.status, Ticket.Classificationid, Classstructure.Description CLASS_DESCRIPTION, ticket.description, REGEXP_REPLACE(Longdescription.Ldtext,'<[^>]*>',' ') LONG_DESCRIPTION, Asset.Assettag, Assetclass.Description asset_class, Ci.Ciname, ciclass.Description ci_class, Person.Displayname, person.company, Person.Department, Person.Deptdesc
from ticket, person, asset, CI, Longdescription, classstructure, classstructure assetclass, classstructure ciclass
where Ticket.Affectedperson = Person.Personid
and Ticket.Assetnum = asset.assetnum(+)
and Ticket.Cinum = ci.cinum(+)
and Longdescription.ldkey = Ticket.Ticketuid
and Classstructure.Classstructureid = Ticket.Classstructureid
and Assetclass.Classstructureid(+) = Asset.Classstructureid
and ciclass.Classstructureid(+) = Ci.Classstructureid
-- Filters
and Longdescription.Ldownertable = 'TICKET'
and ticket.class in ('SR', 'INCIDENT')
  and not exists (select *
                  from RELATEDRECORD
                  where class = 'SR' and RELATEDRECCLASS = 'INCIDENT' and relatetype = 'FOLLOWUP'
                    and relatedrecord.recordkey = ticket.ticketid);
