--Script:
DECLARE
  v_tbname varchar2(50);
  v_colname varchar(50);
  v_seqname varchar2(50);
  v_sequence_max number;
  v_new_seq_value int;
  v_sql_max varchar2(200);
  cursor C1 is
          select tbname, name, sequencename
          from maxsequence
        where existS (select 1 from maxobject where objectname = maxsequence.tbname and persistent=1)
          and exists (select 1 from maxattribute where objectname = maxsequence.tbname and attributename =name and persistent=1)
        order by tbname,name, sequencename;

BEGIN
  OPEN C1;
  v_new_seq_value := 0;
  v_sequence_max :=0;
  LOOP
   FETCH C1 into v_tbname, v_colname, v_seqname;
   EXIT when C1%NOTFOUND;
   v_sql_max := 'select max('||v_colname||') from maximo.'||v_tbname||' where '||v_colname||' between ';
   v_sql_max := v_sql_max||'''1''';
   v_sql_max := v_sql_max||' and ';
   v_sql_max := v_sql_max||'''999999999999''';
   DBMS_OUTPUT.PUT_LINE('Table : '||v_tbname);
   DBMS_OUTPUT.PUT_LINE('Seq Col : '||v_colname);
   DBMS_OUTPUT.PUT_LINE('Sql Max : '||v_sql_max);
   EXECUTE IMMEDIATE v_sql_max into v_sequence_max;
   IF v_sequence_max is NULL THEN
      v_sequence_max :=0;
   ELSE
      v_new_seq_value := v_sequence_max + 100;
      DBMS_OUTPUT.PUT_LINE('Cur Value : '||v_sequence_max);
      DBMS_OUTPUT.PUT_LINE('New Value : '||v_new_seq_value);
      v_new_seq_value := 0;
      v_sequence_max :=0;
   END IF;
  END LOOP;
  CLOSE C1;
END;

--Select with of character:
select max(requestnum) from maximo.INVRESERVE;

--Select with null value:
select max(DPAMPROCVARIANTID) from maximo.DPAMPROCVARIANT
