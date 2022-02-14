--Find all references to a conditional expression
--
--Conditional expressions are one of the most powerful tool in the hand of a skilled TPAE specialist. However, when things get complex it may be hard to track where all custom conditional expression are referenced in your environment. That's why I have spent some minutes developing a small set of SQL queries to list those references from the TPAE database.
--First of all, conditional expressions are stored in the CONDITION table. The other tables that has reference to this table are:
--
--    CTRLCONDITION/CTRLGROUP
--    APPLICATIONAUTH
--    SECURITYRESTRICT
--    MAXDOMVALCOND
--    CROSSOVERDOMAIN
--
--Let's look at all these tables one by one.
--
--CTRLCONDITION/CTRLGROUP
--Conditional Expressions can be used into Application Designer through the 'Configure Conditional Properties' button. These conditions can then be used to set specific properties to a UI control.

SELECT ctrlgroup.app, ctrlgroup.optionname, ctrlgroup.groupname, ctrlcondition.conditionnum
FROM ctrlcondition 
JOIN ctrlgroup ON ctrlgroup.ctrlgroupid=ctrlcondition.ctrlgroupid
JOIN condition ON condition.conditionnum=ctrlcondition.conditionnum
WHERE ctrlcondition.conditionnum IS NOT NULL;


--APPLICATIONAUTH
--Applications SigOptions can be activated upon the evaluation of a Conditional Expression (see Security - Security Groups - Applications)
--The following query will list all the SigOption with a bounded conditional expression together with all the applications and groups.

SELECT a.app, a.groupname, a.optionname, a.conditionnum, c.expression, c.type
FROM applicationauth a
JOIN condition c ON a.conditionnum=c.conditionnum
WHERE a.conditionnum IS NOT NULL;


--If you are not interested in which group has access to a specific SigOption the following query returns a much shorter list.

SELECT a.app, a.optionname, a.conditionnum, c.description, c.expression, c.type
FROM applicationauth a
JOIN condition c ON a.conditionnum=c.conditionnum
WHERE a.conditionnum IS NOT NULL
GROUP BY a.app, a.optionname, a.conditionnum, c.description, c.expression, c.type;


--After having identified the SigOption, you can check the application presentation XML to find the linked control.

--SECURITYRESTRICT
--Security restrictions can be applied to an object or an attribute and can be linked to a Conditional Expression (see Security - Security Groups - Select Action Menu - Global Data Restrictions)

select * from SECURITYRESTRICT;


--MAXDOMVALCOND
--Conditions can be set on crossover domains (see System Configuration - Platform Configurations - Domains - ALN Domain)

SELECT * FROM maxdomvalcond WHERE conditionnum IS NOT NULL;


--CROSSOVERDOMAIN
--Conditions can be set on crossover domains (see System Configuration - Platform Configurations - Domains - Crossover Domain

SELECT * FROM crossoverdomain WHERE destcondition IS NOT NULL or sourcecondition IS NOT NULL;