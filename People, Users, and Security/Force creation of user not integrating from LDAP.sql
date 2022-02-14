-- Note!  Check the old user record's loginid.  It can't match the new user record or it won't integrate.

DECLARE 
    -- Change User ID here for new user
    NewUserID VARCHAR(20) := 'BABABABBA';

begin

insert 
into maximo.maxuser
    (userid, personid, status, type, defsite, querywithsite, defstoreroom, storeroomsite,
    forceexpiration, failedlogins,password, loginid, maxuserid, sysuser, inactivesites, screenreader, isconsultant, sidenav)

    select
       upper(NewUserID),upper(NewUserID),'ACTIVE','TYPE 1','SITE_BCF','1','CENTRAL','SITE_BCF','0','0',         
        '32EADE0476E14525346CF4CB6AB03BD8DA390D7D6451D979',   
        lower(NewUserID), maximo.maxuserseq.nextval,'0','0','0','0','0' 
    FROM dual
    where not exists (select 1 from maximo.maxuser where userid = upper(NewUserID));
commit;
end;
/
