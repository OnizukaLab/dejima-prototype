CREATE OR REPLACE PROCEDURE public.transaction_B(rid integer, wid integer) LANGUAGE plpgsql AS $$ 
DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
BEGIN
  -- statements
  PERFORM * FROM bt_lineage WHERE id=rid FOR SHARE NOWAIT;
  PERFORM * FROM bt_lineage WHERE id=wid FOR UPDATE NOWAIT;
  UPDATE bt SET col1=left(md5(col2), 5), col2=left(md5(col3), 5), col3=left(md5(col1), 5) WHERE id=wid;
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