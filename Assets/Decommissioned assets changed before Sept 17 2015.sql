SELECT asset.status, classstructure.description, count(*)
FROM asset
  JOIN locations ON asset.LOCATION = locations.LOCATION
  join classstructure on classstructure.classstructureid = asset.classstructureid
WHERE asset.status IN ('DECOMMISSIONED')
  and asset.classstructureid in (select classstructureid
                                from classstructure
                                where classstructureid in (select classstructureid from MAXIMO.classusewith where objectvalue = 'ASSET')
                                  and (upper(description) like '%DESKTOP%'
                                    or upper(description) like '%LAPTOP%'
                                    or upper(description) like '%TABLET%'
                                    or upper(description) like '%SMART PHONE%'
                                    or upper(description) like '%MOBILE PHONE%'))
  and ASSET.STATUSDATE <= to_date('17-SEP-2015', 'dd-MON-yyyy')
group by asset.status, classstructure.description;