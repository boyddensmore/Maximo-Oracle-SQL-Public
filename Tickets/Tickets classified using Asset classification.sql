SELECT class, Ticketid, status, Classificationid, Createdby
FROM ticket
WHERE Classstructureid IN
  (SELECT classstructureid
  FROM classstructure
  WHERE classificationid IN ('IT','ASSET.GENERIC_COMPUTERSYSTEM','NETEQ','TELECOM','SW','PHYSSEC','ERINFRA','STOREQ','COMPEQ','AUDIOVISUAL','ASSET.GENERIC_COMPUTERSYSTEM','PROJECTORSYS','CAMERA','DISPLAYS','COMPACC','COMPSYS','COMPCOMPS','PRINTER','MOBILE','DESKTOP','PHYSSERV','SMARTPHONE','TABLET','LAPTOP','CABINET','PDU','RACK','UPS','SECDEV','REPEATER','LOADBAL','ROUTER','SWITCH','TAPESYS','HDARRAY','SAN','NAS','SYSTEMMGMT','BUSINESSINTEL','FINANCIAL','SEARCH','PROCESSMGMT','HUMANRESOURCES','COLLAB','DATAMGMT','ASSETCONFIG','FORMSMGMT','ASSETMONITOR','WORKMGMT','OPSMGMT','SUPPLYCHAIN','COMMUNICATION','ENERGYTRADING','ASSETMGMT','DEVANDINTEGR','SECURITYMGMT','VISUALIZATION','CUSTOMERRELMGMT','PBX','MOBILEDATA','DESKPHONE','MOBILEPHONE','CONFPHONE','FAX')
  AND Indicatedpriority  IS NULL
  )
order by Createdby;