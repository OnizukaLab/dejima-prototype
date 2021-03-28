CREATE OR REPLACE PROCEDURE public.transaction_A(id1 integer, id2 integer, v1 varchar(80)) LANGUAGE plpgsql AS $$ 
DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
BEGIN
  -- statements
  PERFORM * FROM bt_lineage WHERE id=id1 FOR SHARE NOWAIT;
  PERFORM * FROM bt_lineage WHERE id=id2 FOR UPDATE NOWAIT;
  PERFORM * FROM bt WHERE id = id1;
  UPDATE bt SET col1=v1 WHERE id=id2;
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