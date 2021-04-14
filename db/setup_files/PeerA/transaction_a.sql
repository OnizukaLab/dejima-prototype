CREATE OR REPLACE PROCEDURE public.transaction_A(
   rid1 integer,
   rid2 integer,
   rid3 integer,
   rid4 integer,
   rid5 integer,
   wid1 integer,
   wid2 integer,
   wid3 integer,
   wid4 integer,
   wid5 integer
) 
LANGUAGE plpgsql AS
$$ 
DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
BEGIN
  -- statements
  RAISE LOG 'ids: %, %, %, %, %, %, %, %, %, %', rid1, rid2, rid3, rid4, rid5, wid1, wid2, wid3, wid4, wid5;
  PERFORM * FROM bt_lineage WHERE id IN (rid1, rid2, rid3, rid4, rid5) FOR SHARE NOWAIT;
  PERFORM * FROM bt_lineage WHERE id IN (wid1, wid2, wid3, wid4, wid5) FOR UPDATE NOWAIT;
  UPDATE bt SET col1=left(md5(col1), 5) WHERE id IN (wid1, wid2, wid3, wid4, wid5);
  SET CONSTRAINTS public.bt_detect_update_on_dejima_a_b IMMEDIATE;
  SET CONSTRAINTS public.bt_detect_update_on_dejima_a_b DEFERRED;
  PERFORM public.terminate();
EXCEPTION
  WHEN others THEN
    GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,
                            text_var2 = PG_EXCEPTION_DETAIL,
                            text_var3 = PG_EXCEPTION_HINT;
    RAISE LOG USING MESSAGE = '[ROLLBACK] ' || text_var1 || text_var2 || text_var3;
    ROLLBACK;
END;
$$