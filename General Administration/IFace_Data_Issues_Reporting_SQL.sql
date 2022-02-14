select * from
(
        --Reservations without planned materials on workorders:
        select distinct WONUM KEY,'WORKORDER' TABLENAME, 
            'Reservations without Planned Materials on Workorder. This is probably due to synch issues of WO''s Planned Materials' Description,
            'FIX' XLEVEL, 'DATA' SRC, '' messageid
        from invreserve i 
        where not exists (select 1 from wpmaterial w where i.wonum = w.wonum and i.itemnum =w.itemnum) 
            and location = 'CENTRAL' and wonum is not null
    
    union all
    
        --jobplan two or more active.
        select distinct JPNUM KEY,'JOBPLAN' TABLENAME, 
            'Job plans with more than one revision active' Description,
            'FIX' XLEVEL, 'DATA' SRC, '' messageid
        from jobplan
        where status ='ACTIVE' 
        group by jpnum,status 
        having count(1)>1
    
    union all
    
        --Workorders not in synch on shore.
        select distinct t.key as key ,'WORKORDER' TABLENAME,
            'Workorder ' || nvl((select 'seems not in synch: Shore Status:'|| status from workorder where wonum=t.key),'is not found on shore') description,
            'FIX' XLEVEL, 'IFACE' SRC, to_char(t.messageid)
        from
        (
            select e.messageid, substr(error,24,instr(error,' is not a valid parent work order.')-24) KEY,'WORKORDER' TABLENAME
            from MAXINTERROR e,MAXINTERRORMSG m
            where m.messageid=e.messageid and e.status in ('HOLD','RETRY') and deleteflag =0
                and error like 'BMXAA4566E%' and IFACENAME='BCFWODETAILInterface'
         )   T
     
     union all
     
         --double reservations on shore:
        select key ,TABLENAME,
            'Duplicate Reservations found on shore for the item: ' || t.itemnum description,
            'FIX' XLEVEL, 'DATA' SRC, '' messageid
        from
        (
            select nvl(wonum,mrnum) key,decode(wonum,null,'MR','WORKORDER') TABLENAME,itemnum,mrlinenum
            from invreserve
            group by nvl(wonum,mrnum),decode(wonum,null,'MR','WORKORDER'),itemnum,mrlinenum having count(1)>1
        ) T where 
            (
                mrlinenum is null 
                and 
                nvl((select count(1) from wpmaterial p where p.wonum=T.key and p.itemnum=t.itemnum),0)
                != (select count(1) from invreserve i where i.wonum=T.key and i.itemnum=t.itemnum)
            )
            or
            (mrlinenum is not null)

    union all
    
        select nvl(wonum,mrnum) key,decode(wonum,null,'MR','WORKORDER') TABLENAME,
            'Incorrect link between Reservations and Material Planning - Item: '|| itemnum description,
            'WARN' XLEVEL, 'DATA' SRC, '' messageid
        from invreserve r where not exists (select 1 from wpitem where requestnum=r.requestnum)
    
    union all
    
        select mrnum key,'MR' TABLENAME,
            'Reservations found while document is not approved. The document might have been approved on Vessels but status still shows not approve.' description,
            'FIX' XLEVEL , 'DATA' SRC, '' messageid
        from mr m 
        where exists (select 1 from invreserve where mrnum=m.mrnum) 
            and status in (select value from synonymdomain where domainid ='MRSTATUS' and maxvalue in('WAPPR','DRAFT'))
    
    union all
    
        select wonum key,'WORKORDER' TABLENAME,
            'Reservations found while document is not approved. The document might have been approved on Vessels but status still shows not approve.' description,
            'FIX' XLEVEL , 'DATA' SRC, '' messageid
        from workorder m where exists (select 1 from invreserve where wonum=m.wonum) 
        and status in (select value from synonymdomain where domainid ='WOSTATUS' and maxvalue ='WAPPR')
    
    union all
    
        select mrnum key, 'MR' TABLENAME, 
            'Approved but reservations for pending lines are missing - Should not be marked as arrived on shore- Out of Sync..',
            'WARN' XLEVEL, 'DATA' SRC, '' messageid
        from mr where 
        exists (
                        select 1 from mrline l where l.mrnum=mr.mrnum and l.siteid=mr.siteid and l.complete=0
                        and directreq=0 and storeloc is not null
                        and not exists (select 1 from invreserve v where v.mrnum=l.mrnum and v.mrlinenum=l.mrlinenum)
                        and exists (select 1 from item where itemnum = l.itemnum and item.status ='ACTIVE')
                )
        and status in (select value from synonymdomain where domainid ='MRSTATUS' and maxvalue in('APPR','COMP'))
    
    union all
    
        select mrnum key, 'MR' TABLENAME, 
            'PRs not created for Direct Issue MR Lines..',
            'WARN' XLEVEL, 'DATA' SRC, '' messageid
        from mr where 
        exists 
                (
                        select 1 from mrline l where l.mrnum=mr.mrnum and l.siteid=mr.siteid and directreq=1
                        and not exists (select 1 from prline p where p.mrnum=l.mrnum and p.mrlinenum = l.mrlinenum) 
                        and exists (select 1 from item where itemnum = l.itemnum and item.status ='ACTIVE')
                )
        and status in (select value from synonymdomain where domainid ='MRSTATUS' and maxvalue in('APPR','COMP'))
    
    union all
    
        select prnum key, 'PR' TABLENAME,
            'PRs pending for auto-approval using an escalation. Reason: GL Account is incomplete (with ?) on one of its lines' description,
            'FIX'  XLEVEL, 'DATA' SRC, '' messageid
        from pr
        where STATUS = 'WAPPR' AND PRNUM IN (SELECT DISTINCT(PRNUM) FROM PRLINE 
        WHERE MRLINENUM IS NOT NULL and mrnum in (select mrnum from mr where status = 'APPR'))
            and not exists (select 1 from prline l where l.prnum=pr.prnum and l.gldebitacct not like '%?%')
    /*
    union all
    
        select to_char( substr(XMLX,
                    instr(XMLX,decode(ifacename,'BCFPRInterface','<PRNUM>','BCFPOInterface','<PONUM>','<WONUM>'))+7,
                    instr(XMLX,decode(ifacename,'BCFPRInterface','</PRNUM>','BCFPOInterface','</PONUM>','</WONUM>'))-instr(XMLX,decode(ifacename,'BCFPRInterface','<PRNUM>','BCFPOInterface','<PONUM>','<WONUM>'))-7
                 )) KEY, decode(ifacename,'BCFPRInterface','PR','BCFPOInterface','PO','WORKORDER') TABLENAME, 'Record update from vessel not found on shore - Error BMXAA1496' description,'FIX' XLEVEL, 'IFACE' SRC
            from(
                    select e.IFACENAME,m.error, 
                    blob_to_clob(ZLIB_DECOMPRESS(msgdata)) XMLX
                    from MAXINTERROR e,MAXINTERRORMSG m
                    where m.messageid=e.messageid and e.status in ('HOLD','RETRY') 
                    and deleteflag =0 and error like 'BMXAA1496%' and rownum=1
                )
    */
    
    union all
    
        -- Job Plans with DECOMMISSIONED Work Assets
        select JPASSETSPLINK.jpnum KEY, 'JOBPLAN' TABLENAME, 
            'Active Job Plan uses inactive Work Asset: ' || JPASSETSPLINK.assetnum DESCRIPTION, 
            'FIX' XLEVEL, 'DATA' SRC, to_char(e.messageid)
        from MAXINTERROR e,MAXINTERRORMSG m
            join JPASSETSPLINK on JPASSETSPLINK.assetnum = (trim(substr(error,19,instr(error,'is not a valid asset, or its status is not an operating status.')-19)))
        where m.messageid=e.messageid and e.status in ('HOLD','RETRY') and deleteflag =0
            and error like 'BMXAA0090E%' and IFACENAME='BCFJOBPLANInterface'
			
			
			
	union all 
	
		-- Location Hierarchy Issues for ADMINMODE.
		-- Parent has no enrty in the lochierarchy
		Select location,'LOCHIERARCHY' TABLENAME, 'Location hierarchy issues: Parent ' || parent || ' of location ' || location || ' has no entry in the location hierarchy' description
		,'FIX' XLEVEL , 'DATA' SRC , '' messageid 
		from lochierarchy outter 
		where not exists (select 1 from lochierarchy inn where inn.location=outter.parent and inn.systemid=outter.systemid) 
		and parent is not null

	union all
		
		-- Location flagged as having children but found not having any
		Select location,'LOCHIERARCHY' TABLENAME, 'Location hierarchy issues: Location ' || location || ' is flagged as having children while it has no children in the lochierarchy' description
		,'FIX' XLEVEL , 'DATA' SRC , '' messageid
		from lochierarchy outter where children=1 
		and not exists (select 1 from lochierarchy inn where inn.parent=outter.location and inn.systemid=outter.systemid)

	union all
	
		-- Location flagged as having no children but found having at least one
		Select location,'LOCHIERARCHY' TABLENAME, 'Location hierarchy issues: Location ' || location || ' is flagged as having no children while it has children in the lochierarchy' description
		,'FIX' XLEVEL , 'DATA' SRC , '' messageid
		from lochierarchy outter 
		where children=0 and exists (select 1 from lochierarchy inn where inn.parent=outter.location and inn.systemid=outter.systemid)

	union all
		
		-- Location not found in the locations table but in the lochierarchy
		Select location,'LOCHIERARCHY' TABLENAME, 'Location ' || location || ' has entry in the location hierarchy but is not found in the locations table' description
		,'FIX' XLEVEL , 'DATA' SRC , '' messageid 
		from lochierarchy outter 
		where not exists  (select 1 from locations inn where inn.location=outter.location and inn.siteid=outter.siteid)

	union all
	
		-- Parent not found in the locations table but in the lochierarchy
		Select location,'LOCHIERARCHY' TABLENAME, 'Parent ' || location || ' has entry in the location hierarchy but is not found in the locations table' description
		,'FIX' XLEVEL , 'DATA' SRC , '' messageid  
		from lochierarchy outter 
		where not exists  (select 1 from locations inn where inn.location=outter.parent and inn.siteid=outter.siteid) and parent is not null

)
order by xlevel,SRC desc,description ;