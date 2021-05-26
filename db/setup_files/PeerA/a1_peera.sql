
/*view definition (get):
a1(DEJIMA_ID, VID, LOCATION, RID) :- p_0(DEJIMA_ID, VID, LOCATION, RID).
p_0(DEJIMA_ID, VID, LOCATION, RID) :- bt(DEJIMA_ID, VID, LOCATION, RID).
*/

CREATE OR REPLACE VIEW public.a1 AS 
SELECT __dummy__.COL0 AS DEJIMA_ID,__dummy__.COL1 AS VID,__dummy__.COL2 AS LOCATION,__dummy__.COL3 AS RID 
FROM (SELECT a1_a4_0.COL0 AS COL0, a1_a4_0.COL1 AS COL1, a1_a4_0.COL2 AS COL2, a1_a4_0.COL3 AS COL3 
FROM (SELECT p_0_a4_0.COL0 AS COL0, p_0_a4_0.COL1 AS COL1, p_0_a4_0.COL2 AS COL2, p_0_a4_0.COL3 AS COL3 
FROM (SELECT bt_a4_0.DEJIMA_ID AS COL0, bt_a4_0.VID AS COL1, bt_a4_0.LOCATION AS COL2, bt_a4_0.RID AS COL3 
FROM public.bt AS bt_a4_0  ) AS p_0_a4_0  ) AS a1_a4_0  ) AS __dummy__;

CREATE EXTENSION IF NOT EXISTS plsh;

CREATE TABLE IF NOT EXISTS public.__dummy__a1_detected_deletions ( LIKE public.a1 INCLUDING ALL );
CREATE TABLE IF NOT EXISTS public.__dummy__a1_detected_insertions ( LIKE public.a1 INCLUDING ALL );

CREATE OR REPLACE FUNCTION public.a1_get_detected_update_data()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  deletion_data text;
  insertion_data text;
  json_data text;
  BEGIN
    insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM public.__dummy__a1_detected_insertions as t);
    IF insertion_data IS NOT DISTINCT FROM NULL THEN 
        insertion_data := '[]';
    END IF; 
    deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM public.__dummy__a1_detected_deletions as t);
    IF deletion_data IS NOT DISTINCT FROM NULL THEN 
        deletion_data := '[]';
    END IF; 
    IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
        -- calcuate the update data
        json_data := concat('{"view": ' , '"public.a1"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
        -- clear the update data
        DELETE FROM public.__dummy__a1_detected_deletions;
        DELETE FROM public.__dummy__a1_detected_insertions;
    END IF;
    RETURN json_data;
  END;
$$;

CREATE OR REPLACE FUNCTION public.a1_run_shell(text) RETURNS text AS $$
#!/bin/sh

result=$(curl -s -X POST -H "Content-Type: application/json" $DEJIMA_EXECUTION_ENDPOINT -d "$1")
if  [ "$result" = "true" ];  then
    echo "true"
else 
    echo $result
fi
$$ LANGUAGE plsh;

CREATE OR REPLACE FUNCTION public.bt_materialization_for_a1()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
text_var1 text;
text_var2 text;
text_var3 text;
BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = '__temp__Δ_ins_bt_for_a1' OR table_name = '__temp__Δ_del_bt_for_a1')
    THEN
        -- RAISE LOG 'execute procedure bt_materialization_for_a1';
        CREATE TEMPORARY TABLE __temp__Δ_ins_bt_for_a1 ( LIKE public.bt INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE TEMPORARY TABLE __temp__Δ_del_bt_for_a1 ( LIKE public.bt INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE TEMPORARY TABLE __temp__bt_for_a1 WITH OIDS ON COMMIT DROP AS (SELECT * FROM public.bt);
        
    END IF;
    RETURN NULL;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to public.bt';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.bt ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS bt_trigger_materialization_for_a1 ON public.bt;
CREATE TRIGGER bt_trigger_materialization_for_a1
    BEFORE INSERT OR UPDATE OR DELETE ON
    public.bt FOR EACH STATEMENT EXECUTE PROCEDURE public.bt_materialization_for_a1();

CREATE OR REPLACE FUNCTION public.bt_update_for_a1()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
text_var1 text;
text_var2 text;
text_var3 text;
BEGIN
    -- RAISE LOG 'execute procedure bt_update_for_a1';
    IF TG_OP = 'INSERT' THEN
    -- RAISE LOG 'NEW: %', NEW;
    IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update: null value is not accepted';
    END IF;
    DELETE FROM __temp__Δ_del_bt_for_a1 WHERE ROW(DEJIMA_ID,VID,LOCATION,RID) = NEW;
    INSERT INTO __temp__Δ_ins_bt_for_a1 SELECT (NEW).*; 
    ELSIF TG_OP = 'UPDATE' THEN
    IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update: null value is not accepted';
    END IF;
    DELETE FROM __temp__Δ_ins_bt_for_a1 WHERE ROW(DEJIMA_ID,VID,LOCATION,RID) = OLD;
    INSERT INTO __temp__Δ_del_bt_for_a1 SELECT (OLD).*;
    DELETE FROM __temp__Δ_del_bt_for_a1 WHERE ROW(DEJIMA_ID,VID,LOCATION,RID) = NEW;
    INSERT INTO __temp__Δ_ins_bt_for_a1 SELECT (NEW).*; 
    ELSIF TG_OP = 'DELETE' THEN
    -- RAISE LOG 'OLD: %', OLD;
    DELETE FROM __temp__Δ_ins_bt_for_a1 WHERE ROW(DEJIMA_ID,VID,LOCATION,RID) = OLD;
    INSERT INTO __temp__Δ_del_bt_for_a1 SELECT (OLD).*;
    END IF;
    RETURN NULL;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to public.bt';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.bt ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS bt_trigger_update_for_a1 ON public.bt;
CREATE TRIGGER bt_trigger_update_for_a1
    AFTER INSERT OR UPDATE OR DELETE ON
    public.bt FOR EACH ROW EXECUTE PROCEDURE public.bt_update_for_a1();

CREATE OR REPLACE FUNCTION public.bt_detect_update_on_a1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
text_var1 text;
text_var2 text;
text_var3 text;
func text;
tv text;
deletion_data text;
insertion_data text;
json_data text;
result text;
user_name text;
xid text;
BEGIN
IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'bt_detect_update_on_a1_flag') THEN
    CREATE TEMPORARY TABLE bt_detect_update_on_a1_flag ON COMMIT DROP AS (SELECT true as finish);
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'a1_delta_action_flag') THEN
        insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT __dummy__.COL0 AS DEJIMA_ID,__dummy__.COL1 AS VID,__dummy__.COL2 AS LOCATION,__dummy__.COL3 AS RID 
FROM (SELECT ∂_ins_a1_a4_0.COL0 AS COL0, ∂_ins_a1_a4_0.COL1 AS COL1, ∂_ins_a1_a4_0.COL2 AS COL2, ∂_ins_a1_a4_0.COL3 AS COL3 
FROM (SELECT p_0_a4_0.COL0 AS COL0, p_0_a4_0.COL1 AS COL1, p_0_a4_0.COL2 AS COL2, p_0_a4_0.COL3 AS COL3 
FROM (SELECT __temp__Δ_ins_bt_for_a1_a4_0.DEJIMA_ID AS COL0, __temp__Δ_ins_bt_for_a1_a4_0.VID AS COL1, __temp__Δ_ins_bt_for_a1_a4_0.LOCATION AS COL2, __temp__Δ_ins_bt_for_a1_a4_0.RID AS COL3 
FROM __temp__Δ_ins_bt_for_a1 AS __temp__Δ_ins_bt_for_a1_a4_0  ) AS p_0_a4_0  ) AS ∂_ins_a1_a4_0  ) AS __dummy__) as t);
        IF insertion_data IS NOT DISTINCT FROM NULL THEN 
            insertion_data := '[]';
        END IF; 
        deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT __dummy__.COL0 AS DEJIMA_ID,__dummy__.COL1 AS VID,__dummy__.COL2 AS LOCATION,__dummy__.COL3 AS RID 
FROM (SELECT ∂_del_a1_a4_0.COL0 AS COL0, ∂_del_a1_a4_0.COL1 AS COL1, ∂_del_a1_a4_0.COL2 AS COL2, ∂_del_a1_a4_0.COL3 AS COL3 
FROM (SELECT p_0_a4_0.COL0 AS COL0, p_0_a4_0.COL1 AS COL1, p_0_a4_0.COL2 AS COL2, p_0_a4_0.COL3 AS COL3 
FROM (SELECT __temp__Δ_del_bt_for_a1_a4_0.DEJIMA_ID AS COL0, __temp__Δ_del_bt_for_a1_a4_0.VID AS COL1, __temp__Δ_del_bt_for_a1_a4_0.LOCATION AS COL2, __temp__Δ_del_bt_for_a1_a4_0.RID AS COL3 
FROM __temp__Δ_del_bt_for_a1 AS __temp__Δ_del_bt_for_a1_a4_0  ) AS p_0_a4_0  ) AS ∂_del_a1_a4_0  ) AS __dummy__) as t);
        IF deletion_data IS NOT DISTINCT FROM NULL THEN 
            deletion_data := '[]';
        END IF; 
        IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
            user_name := (SELECT session_user);
            IF NOT (user_name = 'dejima') THEN 
                xid := (SELECT txid_current());
                json_data := concat('{"xid": "', xid, '" ,"view": ' , '"public.a1"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
                result := public.a1_run_shell(json_data);
                IF result = 'true' THEN 
                    DROP TABLE __temp__Δ_ins_bt_for_a1;
                    DROP TABLE __temp__Δ_del_bt_for_a1;
                    DROP TABLE __temp__bt_for_a1;
                ELSE
                    CREATE TEMPORARY TABLE IF NOT EXISTS dejima_abort_flag ON COMMIT DROP AS (SELECT true as finish);
                    -- RAISE LOG 'result from running the sh script: %', result;
                    RAISE LOG check_violation USING MESSAGE = 'update on view is rejected by the external tool, result from running the sh script: ' 
                    || result;
                END IF;
            ELSE 
                RAISE LOG 'function of detecting dejima update is called by % , no request sent to dejima proxy', user_name;

                -- update the table that stores the insertions and deletions we calculated
                DELETE FROM public.__dummy__a1_detected_deletions;
                INSERT INTO public.__dummy__a1_detected_deletions
                    SELECT __dummy__.COL0 AS DEJIMA_ID,__dummy__.COL1 AS VID,__dummy__.COL2 AS LOCATION,__dummy__.COL3 AS RID 
FROM (SELECT ∂_del_a1_a4_0.COL0 AS COL0, ∂_del_a1_a4_0.COL1 AS COL1, ∂_del_a1_a4_0.COL2 AS COL2, ∂_del_a1_a4_0.COL3 AS COL3 
FROM (SELECT p_0_a4_0.COL0 AS COL0, p_0_a4_0.COL1 AS COL1, p_0_a4_0.COL2 AS COL2, p_0_a4_0.COL3 AS COL3 
FROM (SELECT __temp__Δ_del_bt_for_a1_a4_0.DEJIMA_ID AS COL0, __temp__Δ_del_bt_for_a1_a4_0.VID AS COL1, __temp__Δ_del_bt_for_a1_a4_0.LOCATION AS COL2, __temp__Δ_del_bt_for_a1_a4_0.RID AS COL3 
FROM __temp__Δ_del_bt_for_a1 AS __temp__Δ_del_bt_for_a1_a4_0  ) AS p_0_a4_0  ) AS ∂_del_a1_a4_0  ) AS __dummy__;

                DELETE FROM public.__dummy__a1_detected_insertions;
                INSERT INTO public.__dummy__a1_detected_insertions
                    SELECT __dummy__.COL0 AS DEJIMA_ID,__dummy__.COL1 AS VID,__dummy__.COL2 AS LOCATION,__dummy__.COL3 AS RID 
FROM (SELECT ∂_ins_a1_a4_0.COL0 AS COL0, ∂_ins_a1_a4_0.COL1 AS COL1, ∂_ins_a1_a4_0.COL2 AS COL2, ∂_ins_a1_a4_0.COL3 AS COL3 
FROM (SELECT p_0_a4_0.COL0 AS COL0, p_0_a4_0.COL1 AS COL1, p_0_a4_0.COL2 AS COL2, p_0_a4_0.COL3 AS COL3 
FROM (SELECT __temp__Δ_ins_bt_for_a1_a4_0.DEJIMA_ID AS COL0, __temp__Δ_ins_bt_for_a1_a4_0.VID AS COL1, __temp__Δ_ins_bt_for_a1_a4_0.LOCATION AS COL2, __temp__Δ_ins_bt_for_a1_a4_0.RID AS COL3 
FROM __temp__Δ_ins_bt_for_a1 AS __temp__Δ_ins_bt_for_a1_a4_0  ) AS p_0_a4_0  ) AS ∂_ins_a1_a4_0  ) AS __dummy__;
            END IF;
        END IF;
    END IF;
END IF;
RETURN NULL;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to public.bt';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the function public.bt_detect_update_on_a1() ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS bt_detect_update_on_a1 ON public.bt;
CREATE CONSTRAINT TRIGGER bt_detect_update_on_a1
    AFTER INSERT OR UPDATE OR DELETE ON
    public.bt DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.bt_detect_update_on_a1();

CREATE OR REPLACE FUNCTION public.bt_propagate_updates_to_a1 ()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  BEGIN
    SET CONSTRAINTS public.bt_detect_update_on_a1 IMMEDIATE;
    SET CONSTRAINTS public.bt_detect_update_on_a1 DEFERRED;
    DROP TABLE IF EXISTS bt_detect_update_on_a1_flag;
    RETURN true;
  END;
$$;



CREATE OR REPLACE FUNCTION public.a1_delta_action()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
  deletion_data text;
  insertion_data text;
  json_data text;
  result text;
  user_name text;
  temprecΔ_del_bt public.bt%ROWTYPE;
temprecΔ_ins_bt public.bt%ROWTYPE;
  BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'a1_delta_action_flag') THEN
        -- RAISE LOG 'execute procedure a1_delta_action';
        CREATE TEMPORARY TABLE a1_delta_action_flag ON COMMIT DROP AS (SELECT true as finish);
        IF EXISTS (SELECT WHERE false )
        THEN 
          RAISE check_violation USING MESSAGE = 'Invalid view update: constraints on the view are violated';
        END IF;
        IF EXISTS (SELECT WHERE false )
        THEN 
          RAISE check_violation USING MESSAGE = 'Invalid view update: constraints on the source relations are violated';
        END IF;
        CREATE TEMPORARY TABLE Δ_del_bt WITH OIDS ON COMMIT DROP AS SELECT (ROW(COL0,COL1,COL2,COL3) :: public.bt).* 
            FROM (SELECT Δ_del_bt_a4_0.COL0 AS COL0, Δ_del_bt_a4_0.COL1 AS COL1, Δ_del_bt_a4_0.COL2 AS COL2, Δ_del_bt_a4_0.COL3 AS COL3 
FROM (SELECT bt_a4_0.DEJIMA_ID AS COL0, bt_a4_0.VID AS COL1, bt_a4_0.LOCATION AS COL2, bt_a4_0.RID AS COL3 
FROM public.bt AS bt_a4_0 
WHERE NOT EXISTS ( SELECT * 
FROM (SELECT a1_a4_0.DEJIMA_ID AS COL0, a1_a4_0.VID AS COL1, a1_a4_0.LOCATION AS COL2, a1_a4_0.RID AS COL3 
FROM public.a1 AS a1_a4_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_a1 AS __temp__Δ_del_a1_a4 
WHERE __temp__Δ_del_a1_a4.RID = a1_a4_0.RID AND __temp__Δ_del_a1_a4.LOCATION = a1_a4_0.LOCATION AND __temp__Δ_del_a1_a4.VID = a1_a4_0.VID AND __temp__Δ_del_a1_a4.DEJIMA_ID = a1_a4_0.DEJIMA_ID )  UNION SELECT __temp__Δ_ins_a1_a4_0.DEJIMA_ID AS COL0, __temp__Δ_ins_a1_a4_0.VID AS COL1, __temp__Δ_ins_a1_a4_0.LOCATION AS COL2, __temp__Δ_ins_a1_a4_0.RID AS COL3 
FROM __temp__Δ_ins_a1 AS __temp__Δ_ins_a1_a4_0  ) AS new_a1_a4 
WHERE new_a1_a4.COL3 = bt_a4_0.RID AND new_a1_a4.COL2 = bt_a4_0.LOCATION AND new_a1_a4.COL1 = bt_a4_0.VID AND new_a1_a4.COL0 = bt_a4_0.DEJIMA_ID ) ) AS Δ_del_bt_a4_0  ) AS Δ_del_bt_extra_alias;

CREATE TEMPORARY TABLE Δ_ins_bt WITH OIDS ON COMMIT DROP AS SELECT (ROW(COL0,COL1,COL2,COL3) :: public.bt).* 
            FROM (SELECT Δ_ins_bt_a4_0.COL0 AS COL0, Δ_ins_bt_a4_0.COL1 AS COL1, Δ_ins_bt_a4_0.COL2 AS COL2, Δ_ins_bt_a4_0.COL3 AS COL3 
FROM (SELECT new_a1_a4_0.COL0 AS COL0, new_a1_a4_0.COL1 AS COL1, new_a1_a4_0.COL2 AS COL2, new_a1_a4_0.COL3 AS COL3 
FROM (SELECT a1_a4_0.DEJIMA_ID AS COL0, a1_a4_0.VID AS COL1, a1_a4_0.LOCATION AS COL2, a1_a4_0.RID AS COL3 
FROM public.a1 AS a1_a4_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_a1 AS __temp__Δ_del_a1_a4 
WHERE __temp__Δ_del_a1_a4.RID = a1_a4_0.RID AND __temp__Δ_del_a1_a4.LOCATION = a1_a4_0.LOCATION AND __temp__Δ_del_a1_a4.VID = a1_a4_0.VID AND __temp__Δ_del_a1_a4.DEJIMA_ID = a1_a4_0.DEJIMA_ID )  UNION SELECT __temp__Δ_ins_a1_a4_0.DEJIMA_ID AS COL0, __temp__Δ_ins_a1_a4_0.VID AS COL1, __temp__Δ_ins_a1_a4_0.LOCATION AS COL2, __temp__Δ_ins_a1_a4_0.RID AS COL3 
FROM __temp__Δ_ins_a1 AS __temp__Δ_ins_a1_a4_0  ) AS new_a1_a4_0 
WHERE NOT EXISTS ( SELECT * 
FROM public.bt AS bt_a4 
WHERE bt_a4.RID = new_a1_a4_0.COL3 AND bt_a4.LOCATION = new_a1_a4_0.COL2 AND bt_a4.VID = new_a1_a4_0.COL1 AND bt_a4.DEJIMA_ID = new_a1_a4_0.COL0 ) ) AS Δ_ins_bt_a4_0  ) AS Δ_ins_bt_extra_alia 
            EXCEPT 
            SELECT * FROM  public.bt; 

FOR temprecΔ_del_bt IN ( SELECT * FROM Δ_del_bt) LOOP 
            DELETE FROM public.bt WHERE ROW(DEJIMA_ID,VID,LOCATION,RID) =  temprecΔ_del_bt;
            END LOOP;
DROP TABLE Δ_del_bt;

INSERT INTO public.bt (SELECT * FROM  Δ_ins_bt) ; 
DROP TABLE Δ_ins_bt;
        
        insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM __temp__Δ_ins_a1) as t);
        IF insertion_data IS NOT DISTINCT FROM NULL THEN 
            insertion_data := '[]';
        END IF; 
        deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM __temp__Δ_del_a1) as t);
        IF deletion_data IS NOT DISTINCT FROM NULL THEN 
            deletion_data := '[]';
        END IF; 
        IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
            user_name := (SELECT session_user);
            IF NOT (user_name = 'dejima') THEN 
                json_data := concat('{"view": ' , '"public.a1"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
                result := public.a1_run_shell(json_data);
                IF NOT (result = 'true') THEN
                    -- RAISE LOG 'result from running the sh script: %', result;
                    RAISE check_violation USING MESSAGE = 'update on view is rejected by the external tool, result from running the sh script: ' 
                    || result;
                END IF;
            ELSE 
                RAISE LOG 'function of detecting dejima update is called by % , no request sent to dejima proxy', user_name;

                -- update the table that stores the insertions and deletions we calculated
                DELETE FROM public.__dummy__a1_detected_deletions;
                INSERT INTO public.__dummy__a1_detected_deletions
                    SELECT * FROM __temp__Δ_del_a1;

                DELETE FROM public.__dummy__a1_detected_insertions;
                INSERT INTO public.__dummy__a1_detected_insertions
                    SELECT * FROM __temp__Δ_ins_a1;
            END IF;
        END IF;
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.a1';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.a1 ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

CREATE OR REPLACE FUNCTION public.a1_materialization()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
  BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = '__temp__Δ_ins_a1' OR table_name = '__temp__Δ_del_a1')
    THEN
        -- RAISE LOG 'execute procedure a1_materialization';
        CREATE TEMPORARY TABLE __temp__Δ_ins_a1 ( LIKE public.a1 INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE CONSTRAINT TRIGGER __temp__a1_trigger_delta_action_ins
        AFTER INSERT OR UPDATE OR DELETE ON 
            __temp__Δ_ins_a1 DEFERRABLE INITIALLY DEFERRED 
            FOR EACH ROW EXECUTE PROCEDURE public.a1_delta_action();

        CREATE TEMPORARY TABLE __temp__Δ_del_a1 ( LIKE public.a1 INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE CONSTRAINT TRIGGER __temp__a1_trigger_delta_action_del
        AFTER INSERT OR UPDATE OR DELETE ON 
            __temp__Δ_del_a1 DEFERRABLE INITIALLY DEFERRED 
            FOR EACH ROW EXECUTE PROCEDURE public.a1_delta_action();
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.a1';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.a1 ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS a1_trigger_materialization ON public.a1;
CREATE TRIGGER a1_trigger_materialization
    BEFORE INSERT OR UPDATE OR DELETE ON
      public.a1 FOR EACH STATEMENT EXECUTE PROCEDURE public.a1_materialization();

CREATE OR REPLACE FUNCTION public.a1_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
  BEGIN
    -- RAISE LOG 'execute procedure a1_update';
    IF TG_OP = 'INSERT' THEN
      -- RAISE LOG 'NEW: %', NEW;
      IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update on view: view does not accept null value';
      END IF;
      DELETE FROM __temp__Δ_del_a1 WHERE ROW(DEJIMA_ID,VID,LOCATION,RID) = NEW;
      INSERT INTO __temp__Δ_ins_a1 SELECT (NEW).*; 
    ELSIF TG_OP = 'UPDATE' THEN
      IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update on view: view does not accept null value';
      END IF;
      DELETE FROM __temp__Δ_ins_a1 WHERE ROW(DEJIMA_ID,VID,LOCATION,RID) = OLD;
      INSERT INTO __temp__Δ_del_a1 SELECT (OLD).*;
      DELETE FROM __temp__Δ_del_a1 WHERE ROW(DEJIMA_ID,VID,LOCATION,RID) = NEW;
      INSERT INTO __temp__Δ_ins_a1 SELECT (NEW).*; 
    ELSIF TG_OP = 'DELETE' THEN
      -- RAISE LOG 'OLD: %', OLD;
      DELETE FROM __temp__Δ_ins_a1 WHERE ROW(DEJIMA_ID,VID,LOCATION,RID) = OLD;
      INSERT INTO __temp__Δ_del_a1 SELECT (OLD).*;
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.a1';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.a1 ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS a1_trigger_update ON public.a1;
CREATE TRIGGER a1_trigger_update
    INSTEAD OF INSERT OR UPDATE OR DELETE ON
      public.a1 FOR EACH ROW EXECUTE PROCEDURE public.a1_update();

CREATE OR REPLACE FUNCTION public.a1_propagate_updates ()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  BEGIN
    SET CONSTRAINTS __temp__a1_trigger_delta_action_ins, __temp__a1_trigger_delta_action_del, public.bt_detect_update_on_a1 IMMEDIATE;
    SET CONSTRAINTS __temp__a1_trigger_delta_action_ins, __temp__a1_trigger_delta_action_del, public.bt_detect_update_on_a1 DEFERRED;
    DROP TABLE IF EXISTS a1_delta_action_flag;
    DROP TABLE IF EXISTS __temp__Δ_del_a1;
    DROP TABLE IF EXISTS __temp__Δ_ins_a1;
    RETURN true;
  END;
$$;

