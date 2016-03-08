SET SERVEROUTPUT ON FORMAT WORD_WRAPPED;
VARIABLE dml_str_curs REFCURSOR;
DECLARE
    CURSOR SA IS
      select MAXATTRIBUTECFG.OBJECTNAME, MAXATTRIBUTECFG.ATTRIBUTENAME
      from MAXATTRIBUTECFG
        join MAXTABLE on MAXATTRIBUTECFG.OBJECTNAME = MAXTABLE.TABLENAME
      where MAXATTRIBUTECFG.SAMEASATTRIBUTE in ('CINUM', 'ACTCINUM')
        and MAXTABLE.ISAUDITTABLE = '0'
        and MAXATTRIBUTECFG.PERSISTENT = '1'
--        and rownum <= 61
        ;
    TYPE table_array_type IS TABLE OF sa%ROWTYPE INDEX BY BINARY_INTEGER;
    table_array    table_array_type;
    dml_str VARCHAR2 (14500);
    cinum VARCHAR2 (150);
BEGIN
  -- specify the CI we're querying
  cinum := '8800';

  -- bulk fetch the list of tables using CIs
  OPEN sa;
  FETCH sa BULK COLLECT INTO table_array;
  CLOSE sa;

-- begin building dynamic query
  dml_str := 'select ci.cinum';

  -- Insert list of joined subquery names
  FOR i IN table_array.first..table_array.last LOOP
    dml_str := dml_str || ', ' || table_array(i).OBJECTNAME || 'CNT.COUNT ' || table_array(i).OBJECTNAME || 'CNT' ;
  END LOOP;
  
  dml_str := dml_str || ' from CI ';
  
  FOR i IN table_array.first..table_array.last LOOP
    dml_str := dml_str || 'left join (select ' || table_array(i).ATTRIBUTENAME || ', count(*) COUNT from ' || table_array(i).OBJECTNAME || ' group by ' || table_array(i).ATTRIBUTENAME || ' ) ' || table_array(i).OBJECTNAME || 'CNT on ' || table_array(i).OBJECTNAME || 'CNT.' || table_array(i).ATTRIBUTENAME || ' = ci.cinum ';
  END LOOP;
  
  dml_str := dml_str || ' where ci.cinum in (''' || CINUM || ''') ';
  
-- end building dynamic query
  
  dbms_output.put_line(dml_str);
--  EXECUTE IMMEDIATE dml_str;

  open :dml_str_curs FOR dml_str;

END;
/

PRINT :dml_str_curs;


