SELECT count(*) asset FROM asset;
SELECT count(*) assetattribute FROM assetattribute;

SELECT count(*) assettrans FROM assettrans;
SELECT count(*) ci FROM ci;
SELECT count(*) cirelation FROM cirelation;
SELECT count(*) doclinks FROM doclinks;
SELECT count(*) invbalances FROM invbalances;
SELECT count(*) inventory FROM inventory;
SELECT count(*) item FROM item;

SELECT count(*) locations FROM locations;
SELECT count(*) site FROM site;

SELECT count(*) pr FROM pr;
SELECT count(*) prline FROM prline;
SELECT count(*) po FROM po;
SELECT count(*) poline FROM poline;
SELECT count(*) invoice FROM invoice;
SELECT count(*) invoiceline FROM invoiceline;
SELECT count(*) matrectrans FROM matrectrans;
SELECT count(*) servrectrans FROM servrectrans;

SELECT count(*) ticket FROM ticket;
SELECT count(*) workorder FROM workorder;
SELECT count(*) jobplan FROM jobplan;
SELECT count(*) pm FROM pm;

SELECT count(*) measurement FROM measurement;
SELECT count(*) meter FROM meter;
SELECT count(*) meterreading FROM meterreading;

SELECT count(*) wfaction FROM wfaction;
SELECT count(*) wfassignment FROM wfassignment;
SELECT count(*) wfinstance FROM wfinstance;
SELECT count(*) wfnode FROM wfnode;
SELECT count(*) wftask FROM wftask;

SELECT count(*) person FROM person;
SELECT count(*) maxuser FROM maxuser;
SELECT count(*) maxgroup FROM maxgroup;

SELECT siteid, count(*) asset FROM asset GROUP BY siteid;
SELECT siteid, count(*) workorder FROM workorder GROUP BY siteid;



SELECT segment_name, segment_type, tablespace_name, SUM(bytes)/1048576 megs
FROM user_extents
GROUP BY segment_name, segment_type, tablespace_name
ORDER BY megs DESC;