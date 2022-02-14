/*******************************************************************************
* Show general details of a safety plan, including hazards, lockouts, and tagouts
*******************************************************************************/

select
    safetyplan.safetyplanid, safetyplan.description,
    '|| WORKASSET || >>' WADIV,
    SPWORKASSET.spworkassetid, SPWORKASSET.workasset,
--    SPWORKASSET_asset.description asset_description,
    SPWORKASSET.worklocation,
--    '|| HAZARD/PREC || >>' HAPDIV,
--    Hsafetylexicon.hazardid Hhazardid,
--    HSPLEXICONLINK.spworkassetid Hspworkassetid, HSPLEXICONLINK.safetylexiconid Hsafetylexiconid, HSPLEXICONLINK.splexiconlinkid Hsplexiconlinkid,
    '|| TAGOUT HAZARD || >>' TAHDIV,
    safetylexicon.hazardid Thazardid,
    SPLEXICONLINK.spworkassetid, SPLEXICONLINK.safetylexiconid, SPLEXICONLINK.splexiconlinkid,
    '|| TAGOUT || >>' TAGDIV,
    Tsafetylexicon.TAGOUTID,
    TSPLEXICONLINK.spworkassetid Tspworkassetid, TSPLEXICONLINK.safetylexiconid Tsafetylexiconid, TSPLEXICONLINK.splexiconlinkid Tsplexiconlinkid
from maximo.safetyplan
--    Work Assets
    left join maximo.SPWORKASSET on (SPWORKASSET.safetyplanid = safetyplan.safetyplanid and SPWORKASSET.siteid=safetyplan.siteid)
    left join maximo.asset SPWORKASSET_asset on SPWORKASSET_asset.assetnum = SPWORKASSET.workasset

--    Hazards
    left join maximo.SPLEXICONLINK HSPLEXICONLINK on (HSPLEXICONLINK.spworkassetid in (select spworkassetid 
                                                            from maximo.spworkasset 
                                                            where safetyplanid = safetyplan.safetyplanid 
                                                                and siteid=safetyplan.siteid) 
                                                        and safetylexiconid in (select safetylexiconid 
                                                                            from maximo.safetylexicon 
                                                                            where hazardid in (select hazardid 
                                                                                                from maximo.hazard 
                                                                                                where precautionenabled = 1 
                                                                                                    and orgid=safetyplan.orgid) 
                                                                                and siteid=safetyplan.siteid) 
                                                        and HSPLEXICONLINK.siteid=safetyplan.siteid)
    left join maximo.safetylexicon Hsafetylexicon on (Hsafetylexicon.safetylexiconid = HSPLEXICONLINK.safetylexiconid)
    
--    Tagouts
    left join maximo.SPLEXICONLINK on (SPLEXICONLINK.spworkassetid in (select spworkassetid 
                                                        from maximo.spworkasset 
                                                        where safetyplanid = safetyplan.safetyplanid 
                                                            and siteid=safetyplan.siteid) 
                                        and SPLEXICONLINK.safetylexiconid in (select safetylexiconid 
                                                                from maximo.safetylexicon 
                                                                where tagoutid is null and hazardid in (select hazardid 
                                                                                                        from maximo.hazard 
                                                                                                        where tagoutenabled = 1 
                                                                                                            and orgid=SPLEXICONLINK.orgid) 
                                                                    and siteid=SPLEXICONLINK.siteid) 
                                        and safetyplan.siteid=SPLEXICONLINK.siteid)
    left join maximo.safetylexicon on (safetylexicon.safetylexiconid = SPLEXICONLINK.safetylexiconid)
    
    
    left join maximo.SPLEXICONLINK TSPLEXICONLINK on (TSPLEXICONLINK.spworkassetid = SPLEXICONLINK.spworkassetid and TSPLEXICONLINK.safetylexiconid in  (select safetylexiconid 
                                                                                                                                            from safetylexicon 
                                                                                                                                            where tagoutid is not null  
                                                                                                                                                and hazardid in (select hazardid 
                                                                                                                                                                from safetylexicon 
                                                                                                                                                                where safetylexiconid = SPLEXICONLINK.safetylexiconid 
                                                                                                                                                                    and siteid=SPLEXICONLINK.siteid) 
                                                                                                                                                and siteid=SPLEXICONLINK.siteid) 
                                                                                                    and TSPLEXICONLINK.siteid=SPLEXICONLINK.siteid)
    left join maximo.safetylexicon Tsafetylexicon on (Tsafetylexicon.safetylexiconid = TSPLEXICONLINK.safetylexiconid)
;