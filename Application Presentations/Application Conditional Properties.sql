/*******************************************************************************
* List conditional properties used in an application
*******************************************************************************/

select ctrlgroup.groupname, ctrlgroup.optionname, ctrlgroup.app,
    CTRLCONDITION.conditionnum,
    CTRLCONDPROP.property, CTRLCONDPROP.propertyvalue, CTRLCONDPROP.conditionresult
from ctrlgroup
    left join CTRLCONDITION on ctrlgroup.CTRLGROUPID = CTRLCONDITION.CTRLGROUPID
    left join CTRLCONDPROP on CTRLCONDITION.CTRLCONDITIONID = CTRLCONDPROP.CTRLCONDITIONID
where ctrlgroup.app in ('CREATEDR', 'PR', 'PR_S1')
    and conditionnum = 'BCFCANITEMEDIT'
;