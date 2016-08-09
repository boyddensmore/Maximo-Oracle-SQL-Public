/*******************************************************************************
*  Set current connection schema to MAXIMO for report simplicity
*******************************************************************************/
ALTER SESSION SET CURRENT_SCHEMA = Maximo;

/*******************************************************************************
*  Show CI update details from past 7 days
*******************************************************************************/
select Ci.Cinum, Ci.Ciname, Hierarchypath.Hierarchypath, Ci.Status, Ci.Changeby , Ci.Changedate, Ci.RFC
from ci
join
    /* Generate HIERARCHYPATH by navigating parents for ClassStructure */
    (select Classstructure.Classstructureid,
      Classstructure.description,
        case when Class_L1.Classstructureid is not null then Class_L1.Classificationid || ' / ' else '' end ||
        case when Class_L2.Classstructureid is not null then Class_L2.Classificationid || ' / ' else '' end ||
        case when Class_L3.Classstructureid is not null then Class_L3.Classificationid || ' / ' else '' end ||
        case when Class_L4.Classstructureid is not null then Class_L4.Classificationid || ' / ' else '' end || 
        Classstructure.Classificationid HIERARCHYPATH
    from Classstructure
      left join Classstructure Class_L4 on Classstructure.Parent = Class_L4.Classstructureid
      left join Classstructure Class_L3 on Class_L4.Parent = Class_L3.Classstructureid
      left join Classstructure Class_L2 on Class_L3.Parent = Class_L2.Classstructureid
      left join Classstructure Class_L1 on Class_L2.Parent = Class_L1.Classstructureid) Hierarchypath on Hierarchypath.Classstructureid = Ci.Classstructureid
where Ci.changedate >= sysdate - 7
and Ci.changeby not in ('[[USERNAME]]');