
/*view definition (get):
jcustomer(KEY, NAME, ADDRESS) :- p_0(KEY, NAME, ADDRESS).
p_0(KEY, NAME, ADDRESS) :- NATION = 'Japan' , customer(KEY, NAME, ADDRESS, COL3, COL4) , nation(COL4, NATION, _).
*/

CREATE OR REPLACE VIEW public.jcustomer AS 
SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME,__dummy__.COL2 AS ADDRESS 
FROM (SELECT jcustomer_a3_0.COL0 AS COL0, jcustomer_a3_0.COL1 AS COL1, jcustomer_a3_0.COL2 AS COL2 
FROM (SELECT p_0_a3_0.COL0 AS COL0, p_0_a3_0.COL1 AS COL1, p_0_a3_0.COL2 AS COL2 
FROM (SELECT customer_a5_0.KEY AS COL0, customer_a5_0.NAME AS COL1, customer_a5_0.ADDRESS AS COL2 
FROM public.customer AS customer_a5_0, public.nation AS nation_a3_1 
WHERE nation_a3_1.KEY = customer_a5_0.NATIONKEY AND nation_a3_1.NAME = 'Japan' ) AS p_0_a3_0  ) AS jcustomer_a3_0  ) AS __dummy__;

CREATE EXTENSION IF NOT EXISTS plsh;

CREATE TABLE public.__dummy__jcustomer_detected_deletions ( LIKE public.jcustomer INCLUDING ALL );
CREATE TABLE public.__dummy__jcustomer_detected_insertions ( LIKE public.jcustomer INCLUDING ALL );

CREATE OR REPLACE FUNCTION public.jcustomer_get_detected_update_data()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  deletion_data text;
  insertion_data text;
  json_data text;
  BEGIN
    insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM public.__dummy__jcustomer_detected_insertions as t);
    IF insertion_data IS NOT DISTINCT FROM NULL THEN 
        insertion_data := '[]';
    END IF; 
    deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM public.__dummy__jcustomer_detected_deletions as t);
    IF deletion_data IS NOT DISTINCT FROM NULL THEN 
        deletion_data := '[]';
    END IF; 
    IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
        -- calcuate the update data
        json_data := concat('{"view": ' , '"public.jcustomer"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
        -- clear the update data
        DELETE FROM public.__dummy__jcustomer_detected_deletions;
        DELETE FROM public.__dummy__jcustomer_detected_insertions;
    END IF;
    RETURN json_data;
  END;
$$;

CREATE OR REPLACE FUNCTION public.jcustomer_run_shell(text) RETURNS text AS $$
#!/bin/sh
echo "true"
$$ LANGUAGE plsh;

CREATE OR REPLACE FUNCTION public.nation_materialization()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
text_var1 text;
text_var2 text;
text_var3 text;
BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = '__temp__Δ_ins_nation' OR table_name = '__temp__Δ_del_nation')
    THEN
        -- RAISE LOG 'execute procedure nation_materialization';
        CREATE TEMPORARY TABLE __temp__Δ_ins_nation ( LIKE public.nation INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE TEMPORARY TABLE __temp__Δ_del_nation ( LIKE public.nation INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE TEMPORARY TABLE __temp__nation WITH OIDS ON COMMIT DROP AS (SELECT * FROM public.nation);
        
    END IF;
    RETURN NULL;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to public.nation';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.nation ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS nation_trigger_materialization ON public.nation;
CREATE TRIGGER nation_trigger_materialization
    BEFORE INSERT OR UPDATE OR DELETE ON
    public.nation FOR EACH STATEMENT EXECUTE PROCEDURE public.nation_materialization();

CREATE OR REPLACE FUNCTION public.nation_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
text_var1 text;
text_var2 text;
text_var3 text;
BEGIN
    -- RAISE LOG 'execute procedure nation_update';
    IF TG_OP = 'INSERT' THEN
    -- RAISE LOG 'NEW: %', NEW;
    IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update: null value is not accepted';
    END IF;
    DELETE FROM __temp__Δ_del_nation WHERE ROW(KEY,NAME,DESCRIPTION) = NEW;
    INSERT INTO __temp__Δ_ins_nation SELECT (NEW).*; 
    ELSIF TG_OP = 'UPDATE' THEN
    IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update: null value is not accepted';
    END IF;
    DELETE FROM __temp__Δ_ins_nation WHERE ROW(KEY,NAME,DESCRIPTION) = OLD;
    INSERT INTO __temp__Δ_del_nation SELECT (OLD).*;
    DELETE FROM __temp__Δ_del_nation WHERE ROW(KEY,NAME,DESCRIPTION) = NEW;
    INSERT INTO __temp__Δ_ins_nation SELECT (NEW).*; 
    ELSIF TG_OP = 'DELETE' THEN
    -- RAISE LOG 'OLD: %', OLD;
    DELETE FROM __temp__Δ_ins_nation WHERE ROW(KEY,NAME,DESCRIPTION) = OLD;
    INSERT INTO __temp__Δ_del_nation SELECT (OLD).*;
    END IF;
    RETURN NULL;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to public.nation';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.nation ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS nation_trigger_update ON public.nation;
CREATE TRIGGER nation_trigger_update
    AFTER INSERT OR UPDATE OR DELETE ON
    public.nation FOR EACH ROW EXECUTE PROCEDURE public.nation_update();

CREATE OR REPLACE FUNCTION public.nation_detect_update_on_jcustomer()
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
BEGIN
IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'jcustomer_delta_action_flag') THEN
    insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME,__dummy__.COL2 AS ADDRESS 
FROM (SELECT ∂_ins_jcustomer_a3_0.COL0 AS COL0, ∂_ins_jcustomer_a3_0.COL1 AS COL1, ∂_ins_jcustomer_a3_0.COL2 AS COL2 
FROM (SELECT p_0_a3_0.COL0 AS COL0, p_0_a3_0.COL1 AS COL1, p_0_a3_0.COL2 AS COL2 
FROM (SELECT customer_a5_1.KEY AS COL0, customer_a5_1.NAME AS COL1, customer_a5_1.ADDRESS AS COL2 
FROM __temp__Δ_ins_nation AS __temp__Δ_ins_nation_a3_0, public.customer AS customer_a5_1 
WHERE customer_a5_1.NATIONKEY = __temp__Δ_ins_nation_a3_0.KEY AND __temp__Δ_ins_nation_a3_0.NAME = 'Japan' AND NOT EXISTS ( SELECT * 
FROM (SELECT customer_a5_1.ADDRESS AS COL0, customer_a5_1.KEY AS COL1, customer_a5_1.NAME AS COL2 
FROM __temp__nation AS __temp__nation_a3_0, public.customer AS customer_a5_1 
WHERE customer_a5_1.NATIONKEY = __temp__nation_a3_0.KEY AND __temp__nation_a3_0.NAME = 'Japan' ) AS p_1_a3 
WHERE p_1_a3.COL2 = customer_a5_1.NAME AND p_1_a3.COL1 = customer_a5_1.KEY AND p_1_a3.COL0 = customer_a5_1.ADDRESS ) ) AS p_0_a3_0  ) AS ∂_ins_jcustomer_a3_0  ) AS __dummy__) as t);
    IF insertion_data IS NOT DISTINCT FROM NULL THEN 
        insertion_data := '[]';
    END IF; 
    deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME,__dummy__.COL2 AS ADDRESS 
FROM (SELECT ∂_del_jcustomer_a3_0.COL0 AS COL0, ∂_del_jcustomer_a3_0.COL1 AS COL1, ∂_del_jcustomer_a3_0.COL2 AS COL2 
FROM (SELECT p_0_a3_0.COL0 AS COL0, p_0_a3_0.COL1 AS COL1, p_0_a3_0.COL2 AS COL2 
FROM (SELECT customer_a5_1.KEY AS COL0, customer_a5_1.NAME AS COL1, customer_a5_1.ADDRESS AS COL2 
FROM __temp__Δ_del_nation AS __temp__Δ_del_nation_a3_0, public.customer AS customer_a5_1 
WHERE customer_a5_1.NATIONKEY = __temp__Δ_del_nation_a3_0.KEY AND __temp__Δ_del_nation_a3_0.NAME = 'Japan' AND NOT EXISTS ( SELECT * 
FROM (SELECT customer_a5_0.ADDRESS AS COL0, customer_a5_0.KEY AS COL1, customer_a5_0.NAME AS COL2 
FROM public.customer AS customer_a5_0, (SELECT __temp__Δ_ins_nation_a3_0.KEY AS COL0, __temp__Δ_ins_nation_a3_0.DESCRIPTION AS COL1, __temp__Δ_ins_nation_a3_0.NAME AS COL2 
FROM __temp__Δ_ins_nation AS __temp__Δ_ins_nation_a3_0   UNION SELECT __temp__nation_a3_0.KEY AS COL0, __temp__nation_a3_0.DESCRIPTION AS COL1, __temp__nation_a3_0.NAME AS COL2 
FROM __temp__nation AS __temp__nation_a3_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_nation AS __temp__Δ_del_nation_a3 
WHERE __temp__Δ_del_nation_a3.DESCRIPTION = __temp__nation_a3_0.DESCRIPTION AND __temp__Δ_del_nation_a3.NAME = __temp__nation_a3_0.NAME AND __temp__Δ_del_nation_a3.KEY = __temp__nation_a3_0.KEY ) ) AS p_2_a3_1 
WHERE p_2_a3_1.COL0 = customer_a5_0.NATIONKEY AND p_2_a3_1.COL2 = 'Japan' ) AS p_1_a3 
WHERE p_1_a3.COL2 = customer_a5_1.NAME AND p_1_a3.COL1 = customer_a5_1.KEY AND p_1_a3.COL0 = customer_a5_1.ADDRESS ) ) AS p_0_a3_0  ) AS ∂_del_jcustomer_a3_0  ) AS __dummy__) as t);
    IF deletion_data IS NOT DISTINCT FROM NULL THEN 
        deletion_data := '[]';
    END IF; 
    IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
        user_name := (SELECT session_user);
        IF NOT (user_name = 'dejima') THEN 
            json_data := concat('{"view": ' , '"public.jcustomer"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
            result := public.jcustomer_run_shell(json_data);
            IF result = 'true' THEN 
                DROP TABLE __temp__Δ_ins_nation;
                DROP TABLE __temp__Δ_del_nation;
                DROP TABLE __temp__nation;
            ELSE
                -- RAISE LOG 'result from running the sh script: %', result;
                RAISE check_violation USING MESSAGE = 'update on view is rejected by the external tool, result from running the sh script: ' 
                || result;
            END IF;
        ELSE 
            -- RAISE LOG 'function of detecting dejima update is called by % , no request sent to dejima proxy', user_name;

            -- update the table that stores the insertions and deletions we calculated
            DELETE FROM public.__dummy__jcustomer_detected_deletions;
            INSERT INTO public.__dummy__jcustomer_detected_deletions
                SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME,__dummy__.COL2 AS ADDRESS 
FROM (SELECT ∂_del_jcustomer_a3_0.COL0 AS COL0, ∂_del_jcustomer_a3_0.COL1 AS COL1, ∂_del_jcustomer_a3_0.COL2 AS COL2 
FROM (SELECT p_0_a3_0.COL0 AS COL0, p_0_a3_0.COL1 AS COL1, p_0_a3_0.COL2 AS COL2 
FROM (SELECT customer_a5_1.KEY AS COL0, customer_a5_1.NAME AS COL1, customer_a5_1.ADDRESS AS COL2 
FROM __temp__Δ_del_nation AS __temp__Δ_del_nation_a3_0, public.customer AS customer_a5_1 
WHERE customer_a5_1.NATIONKEY = __temp__Δ_del_nation_a3_0.KEY AND __temp__Δ_del_nation_a3_0.NAME = 'Japan' AND NOT EXISTS ( SELECT * 
FROM (SELECT customer_a5_0.ADDRESS AS COL0, customer_a5_0.KEY AS COL1, customer_a5_0.NAME AS COL2 
FROM public.customer AS customer_a5_0, (SELECT __temp__Δ_ins_nation_a3_0.KEY AS COL0, __temp__Δ_ins_nation_a3_0.DESCRIPTION AS COL1, __temp__Δ_ins_nation_a3_0.NAME AS COL2 
FROM __temp__Δ_ins_nation AS __temp__Δ_ins_nation_a3_0   UNION SELECT __temp__nation_a3_0.KEY AS COL0, __temp__nation_a3_0.DESCRIPTION AS COL1, __temp__nation_a3_0.NAME AS COL2 
FROM __temp__nation AS __temp__nation_a3_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_nation AS __temp__Δ_del_nation_a3 
WHERE __temp__Δ_del_nation_a3.DESCRIPTION = __temp__nation_a3_0.DESCRIPTION AND __temp__Δ_del_nation_a3.NAME = __temp__nation_a3_0.NAME AND __temp__Δ_del_nation_a3.KEY = __temp__nation_a3_0.KEY ) ) AS p_2_a3_1 
WHERE p_2_a3_1.COL0 = customer_a5_0.NATIONKEY AND p_2_a3_1.COL2 = 'Japan' ) AS p_1_a3 
WHERE p_1_a3.COL2 = customer_a5_1.NAME AND p_1_a3.COL1 = customer_a5_1.KEY AND p_1_a3.COL0 = customer_a5_1.ADDRESS ) ) AS p_0_a3_0  ) AS ∂_del_jcustomer_a3_0  ) AS __dummy__;

            DELETE FROM public.__dummy__jcustomer_detected_insertions;
            INSERT INTO public.__dummy__jcustomer_detected_insertions
                SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME,__dummy__.COL2 AS ADDRESS 
FROM (SELECT ∂_ins_jcustomer_a3_0.COL0 AS COL0, ∂_ins_jcustomer_a3_0.COL1 AS COL1, ∂_ins_jcustomer_a3_0.COL2 AS COL2 
FROM (SELECT p_0_a3_0.COL0 AS COL0, p_0_a3_0.COL1 AS COL1, p_0_a3_0.COL2 AS COL2 
FROM (SELECT customer_a5_1.KEY AS COL0, customer_a5_1.NAME AS COL1, customer_a5_1.ADDRESS AS COL2 
FROM __temp__Δ_ins_nation AS __temp__Δ_ins_nation_a3_0, public.customer AS customer_a5_1 
WHERE customer_a5_1.NATIONKEY = __temp__Δ_ins_nation_a3_0.KEY AND __temp__Δ_ins_nation_a3_0.NAME = 'Japan' AND NOT EXISTS ( SELECT * 
FROM (SELECT customer_a5_1.ADDRESS AS COL0, customer_a5_1.KEY AS COL1, customer_a5_1.NAME AS COL2 
FROM __temp__nation AS __temp__nation_a3_0, public.customer AS customer_a5_1 
WHERE customer_a5_1.NATIONKEY = __temp__nation_a3_0.KEY AND __temp__nation_a3_0.NAME = 'Japan' ) AS p_1_a3 
WHERE p_1_a3.COL2 = customer_a5_1.NAME AND p_1_a3.COL1 = customer_a5_1.KEY AND p_1_a3.COL0 = customer_a5_1.ADDRESS ) ) AS p_0_a3_0  ) AS ∂_ins_jcustomer_a3_0  ) AS __dummy__;
        END IF;
    END IF;
END IF;
RETURN NULL;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to public.nation';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the function public.nation_detect_update_on_jcustomer() ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS nation_detect_update_on_jcustomer ON public.nation;
CREATE TRIGGER nation_detect_update_on_jcustomer
    AFTER INSERT OR UPDATE OR DELETE ON
    public.nation FOR EACH STATEMENT EXECUTE PROCEDURE public.nation_detect_update_on_jcustomer();


 

CREATE OR REPLACE FUNCTION public.customer_materialization()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
text_var1 text;
text_var2 text;
text_var3 text;
BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = '__temp__Δ_ins_customer' OR table_name = '__temp__Δ_del_customer')
    THEN
        -- RAISE LOG 'execute procedure customer_materialization';
        CREATE TEMPORARY TABLE __temp__Δ_ins_customer ( LIKE public.customer INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE TEMPORARY TABLE __temp__Δ_del_customer ( LIKE public.customer INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE TEMPORARY TABLE __temp__customer WITH OIDS ON COMMIT DROP AS (SELECT * FROM public.customer);
        
    END IF;
    RETURN NULL;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to public.customer';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.customer ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS customer_trigger_materialization ON public.customer;
CREATE TRIGGER customer_trigger_materialization
    BEFORE INSERT OR UPDATE OR DELETE ON
    public.customer FOR EACH STATEMENT EXECUTE PROCEDURE public.customer_materialization();

CREATE OR REPLACE FUNCTION public.customer_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
text_var1 text;
text_var2 text;
text_var3 text;
BEGIN
    -- RAISE LOG 'execute procedure customer_update';
    IF TG_OP = 'INSERT' THEN
    -- RAISE LOG 'NEW: %', NEW;
    IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update: null value is not accepted';
    END IF;
    DELETE FROM __temp__Δ_del_customer WHERE ROW(KEY,NAME,ADDRESS,PHONE,NATIONKEY) = NEW;
    INSERT INTO __temp__Δ_ins_customer SELECT (NEW).*; 
    ELSIF TG_OP = 'UPDATE' THEN
    IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update: null value is not accepted';
    END IF;
    DELETE FROM __temp__Δ_ins_customer WHERE ROW(KEY,NAME,ADDRESS,PHONE,NATIONKEY) = OLD;
    INSERT INTO __temp__Δ_del_customer SELECT (OLD).*;
    DELETE FROM __temp__Δ_del_customer WHERE ROW(KEY,NAME,ADDRESS,PHONE,NATIONKEY) = NEW;
    INSERT INTO __temp__Δ_ins_customer SELECT (NEW).*; 
    ELSIF TG_OP = 'DELETE' THEN
    -- RAISE LOG 'OLD: %', OLD;
    DELETE FROM __temp__Δ_ins_customer WHERE ROW(KEY,NAME,ADDRESS,PHONE,NATIONKEY) = OLD;
    INSERT INTO __temp__Δ_del_customer SELECT (OLD).*;
    END IF;
    RETURN NULL;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to public.customer';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.customer ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS customer_trigger_update ON public.customer;
CREATE TRIGGER customer_trigger_update
    AFTER INSERT OR UPDATE OR DELETE ON
    public.customer FOR EACH ROW EXECUTE PROCEDURE public.customer_update();

CREATE OR REPLACE FUNCTION public.customer_detect_update_on_jcustomer()
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
BEGIN
IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'jcustomer_delta_action_flag') THEN
    insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME,__dummy__.COL2 AS ADDRESS 
FROM (SELECT ∂_ins_jcustomer_a3_0.COL0 AS COL0, ∂_ins_jcustomer_a3_0.COL1 AS COL1, ∂_ins_jcustomer_a3_0.COL2 AS COL2 
FROM (SELECT p_0_a3_0.COL0 AS COL0, p_0_a3_0.COL1 AS COL1, p_0_a3_0.COL2 AS COL2 
FROM (SELECT __temp__Δ_ins_customer_a5_0.KEY AS COL0, __temp__Δ_ins_customer_a5_0.NAME AS COL1, __temp__Δ_ins_customer_a5_0.ADDRESS AS COL2 
FROM __temp__Δ_ins_customer AS __temp__Δ_ins_customer_a5_0, public.nation AS nation_a3_1 
WHERE nation_a3_1.KEY = __temp__Δ_ins_customer_a5_0.NATIONKEY AND nation_a3_1.NAME = 'Japan' AND NOT EXISTS ( SELECT * 
FROM (SELECT __temp__customer_a5_0.ADDRESS AS COL0, __temp__customer_a5_0.KEY AS COL1, __temp__customer_a5_0.NAME AS COL2 
FROM __temp__customer AS __temp__customer_a5_0, public.nation AS nation_a3_1 
WHERE nation_a3_1.KEY = __temp__customer_a5_0.NATIONKEY AND nation_a3_1.NAME = 'Japan' ) AS p_1_a3 
WHERE p_1_a3.COL2 = __temp__Δ_ins_customer_a5_0.NAME AND p_1_a3.COL1 = __temp__Δ_ins_customer_a5_0.KEY AND p_1_a3.COL0 = __temp__Δ_ins_customer_a5_0.ADDRESS ) ) AS p_0_a3_0  ) AS ∂_ins_jcustomer_a3_0  ) AS __dummy__) as t);
    IF insertion_data IS NOT DISTINCT FROM NULL THEN 
        insertion_data := '[]';
    END IF; 
    deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME,__dummy__.COL2 AS ADDRESS 
FROM (SELECT ∂_del_jcustomer_a3_0.COL0 AS COL0, ∂_del_jcustomer_a3_0.COL1 AS COL1, ∂_del_jcustomer_a3_0.COL2 AS COL2 
FROM (SELECT p_0_a3_0.COL0 AS COL0, p_0_a3_0.COL1 AS COL1, p_0_a3_0.COL2 AS COL2 
FROM (SELECT __temp__Δ_del_customer_a5_0.KEY AS COL0, __temp__Δ_del_customer_a5_0.NAME AS COL1, __temp__Δ_del_customer_a5_0.ADDRESS AS COL2 
FROM __temp__Δ_del_customer AS __temp__Δ_del_customer_a5_0, public.nation AS nation_a3_1 
WHERE nation_a3_1.KEY = __temp__Δ_del_customer_a5_0.NATIONKEY AND nation_a3_1.NAME = 'Japan' AND NOT EXISTS ( SELECT * 
FROM (SELECT p_2_a5_1.COL0 AS COL0, p_2_a5_1.COL3 AS COL1, p_2_a5_1.COL4 AS COL2 
FROM public.nation AS nation_a3_0, (SELECT __temp__Δ_ins_customer_a5_0.ADDRESS AS COL0, __temp__Δ_ins_customer_a5_0.PHONE AS COL1, __temp__Δ_ins_customer_a5_0.NATIONKEY AS COL2, __temp__Δ_ins_customer_a5_0.KEY AS COL3, __temp__Δ_ins_customer_a5_0.NAME AS COL4 
FROM __temp__Δ_ins_customer AS __temp__Δ_ins_customer_a5_0   UNION SELECT __temp__customer_a5_0.ADDRESS AS COL0, __temp__customer_a5_0.PHONE AS COL1, __temp__customer_a5_0.NATIONKEY AS COL2, __temp__customer_a5_0.KEY AS COL3, __temp__customer_a5_0.NAME AS COL4 
FROM __temp__customer AS __temp__customer_a5_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_customer AS __temp__Δ_del_customer_a5 
WHERE __temp__Δ_del_customer_a5.NATIONKEY = __temp__customer_a5_0.NATIONKEY AND __temp__Δ_del_customer_a5.PHONE = __temp__customer_a5_0.PHONE AND __temp__Δ_del_customer_a5.ADDRESS = __temp__customer_a5_0.ADDRESS AND __temp__Δ_del_customer_a5.NAME = __temp__customer_a5_0.NAME AND __temp__Δ_del_customer_a5.KEY = __temp__customer_a5_0.KEY ) ) AS p_2_a5_1 
WHERE p_2_a5_1.COL2 = nation_a3_0.KEY AND nation_a3_0.NAME = 'Japan' ) AS p_1_a3 
WHERE p_1_a3.COL2 = __temp__Δ_del_customer_a5_0.NAME AND p_1_a3.COL1 = __temp__Δ_del_customer_a5_0.KEY AND p_1_a3.COL0 = __temp__Δ_del_customer_a5_0.ADDRESS ) ) AS p_0_a3_0  ) AS ∂_del_jcustomer_a3_0  ) AS __dummy__) as t);
    IF deletion_data IS NOT DISTINCT FROM NULL THEN 
        deletion_data := '[]';
    END IF; 
    IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
        user_name := (SELECT session_user);
        IF NOT (user_name = 'dejima') THEN 
            json_data := concat('{"view": ' , '"public.jcustomer"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
            result := public.jcustomer_run_shell(json_data);
            IF result = 'true' THEN 
                DROP TABLE __temp__Δ_ins_customer;
                DROP TABLE __temp__Δ_del_customer;
                DROP TABLE __temp__customer;
            ELSE
                -- RAISE LOG 'result from running the sh script: %', result;
                RAISE check_violation USING MESSAGE = 'update on view is rejected by the external tool, result from running the sh script: ' 
                || result;
            END IF;
        ELSE 
            -- RAISE LOG 'function of detecting dejima update is called by % , no request sent to dejima proxy', user_name;

            -- update the table that stores the insertions and deletions we calculated
            DELETE FROM public.__dummy__jcustomer_detected_deletions;
            INSERT INTO public.__dummy__jcustomer_detected_deletions
                SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME,__dummy__.COL2 AS ADDRESS 
FROM (SELECT ∂_del_jcustomer_a3_0.COL0 AS COL0, ∂_del_jcustomer_a3_0.COL1 AS COL1, ∂_del_jcustomer_a3_0.COL2 AS COL2 
FROM (SELECT p_0_a3_0.COL0 AS COL0, p_0_a3_0.COL1 AS COL1, p_0_a3_0.COL2 AS COL2 
FROM (SELECT __temp__Δ_del_customer_a5_0.KEY AS COL0, __temp__Δ_del_customer_a5_0.NAME AS COL1, __temp__Δ_del_customer_a5_0.ADDRESS AS COL2 
FROM __temp__Δ_del_customer AS __temp__Δ_del_customer_a5_0, public.nation AS nation_a3_1 
WHERE nation_a3_1.KEY = __temp__Δ_del_customer_a5_0.NATIONKEY AND nation_a3_1.NAME = 'Japan' AND NOT EXISTS ( SELECT * 
FROM (SELECT p_2_a5_1.COL0 AS COL0, p_2_a5_1.COL3 AS COL1, p_2_a5_1.COL4 AS COL2 
FROM public.nation AS nation_a3_0, (SELECT __temp__Δ_ins_customer_a5_0.ADDRESS AS COL0, __temp__Δ_ins_customer_a5_0.PHONE AS COL1, __temp__Δ_ins_customer_a5_0.NATIONKEY AS COL2, __temp__Δ_ins_customer_a5_0.KEY AS COL3, __temp__Δ_ins_customer_a5_0.NAME AS COL4 
FROM __temp__Δ_ins_customer AS __temp__Δ_ins_customer_a5_0   UNION SELECT __temp__customer_a5_0.ADDRESS AS COL0, __temp__customer_a5_0.PHONE AS COL1, __temp__customer_a5_0.NATIONKEY AS COL2, __temp__customer_a5_0.KEY AS COL3, __temp__customer_a5_0.NAME AS COL4 
FROM __temp__customer AS __temp__customer_a5_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_customer AS __temp__Δ_del_customer_a5 
WHERE __temp__Δ_del_customer_a5.NATIONKEY = __temp__customer_a5_0.NATIONKEY AND __temp__Δ_del_customer_a5.PHONE = __temp__customer_a5_0.PHONE AND __temp__Δ_del_customer_a5.ADDRESS = __temp__customer_a5_0.ADDRESS AND __temp__Δ_del_customer_a5.NAME = __temp__customer_a5_0.NAME AND __temp__Δ_del_customer_a5.KEY = __temp__customer_a5_0.KEY ) ) AS p_2_a5_1 
WHERE p_2_a5_1.COL2 = nation_a3_0.KEY AND nation_a3_0.NAME = 'Japan' ) AS p_1_a3 
WHERE p_1_a3.COL2 = __temp__Δ_del_customer_a5_0.NAME AND p_1_a3.COL1 = __temp__Δ_del_customer_a5_0.KEY AND p_1_a3.COL0 = __temp__Δ_del_customer_a5_0.ADDRESS ) ) AS p_0_a3_0  ) AS ∂_del_jcustomer_a3_0  ) AS __dummy__;

            DELETE FROM public.__dummy__jcustomer_detected_insertions;
            INSERT INTO public.__dummy__jcustomer_detected_insertions
                SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME,__dummy__.COL2 AS ADDRESS 
FROM (SELECT ∂_ins_jcustomer_a3_0.COL0 AS COL0, ∂_ins_jcustomer_a3_0.COL1 AS COL1, ∂_ins_jcustomer_a3_0.COL2 AS COL2 
FROM (SELECT p_0_a3_0.COL0 AS COL0, p_0_a3_0.COL1 AS COL1, p_0_a3_0.COL2 AS COL2 
FROM (SELECT __temp__Δ_ins_customer_a5_0.KEY AS COL0, __temp__Δ_ins_customer_a5_0.NAME AS COL1, __temp__Δ_ins_customer_a5_0.ADDRESS AS COL2 
FROM __temp__Δ_ins_customer AS __temp__Δ_ins_customer_a5_0, public.nation AS nation_a3_1 
WHERE nation_a3_1.KEY = __temp__Δ_ins_customer_a5_0.NATIONKEY AND nation_a3_1.NAME = 'Japan' AND NOT EXISTS ( SELECT * 
FROM (SELECT __temp__customer_a5_0.ADDRESS AS COL0, __temp__customer_a5_0.KEY AS COL1, __temp__customer_a5_0.NAME AS COL2 
FROM __temp__customer AS __temp__customer_a5_0, public.nation AS nation_a3_1 
WHERE nation_a3_1.KEY = __temp__customer_a5_0.NATIONKEY AND nation_a3_1.NAME = 'Japan' ) AS p_1_a3 
WHERE p_1_a3.COL2 = __temp__Δ_ins_customer_a5_0.NAME AND p_1_a3.COL1 = __temp__Δ_ins_customer_a5_0.KEY AND p_1_a3.COL0 = __temp__Δ_ins_customer_a5_0.ADDRESS ) ) AS p_0_a3_0  ) AS ∂_ins_jcustomer_a3_0  ) AS __dummy__;
        END IF;
    END IF;
END IF;
RETURN NULL;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to public.customer';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the function public.customer_detect_update_on_jcustomer() ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS customer_detect_update_on_jcustomer ON public.customer;
CREATE TRIGGER customer_detect_update_on_jcustomer
    AFTER INSERT OR UPDATE OR DELETE ON
    public.customer FOR EACH STATEMENT EXECUTE PROCEDURE public.customer_detect_update_on_jcustomer();



CREATE OR REPLACE FUNCTION public.jcustomer_delta_action()
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
  temprecΔ_del_customer public.customer%ROWTYPE;
temprecΔ_ins_customer public.customer%ROWTYPE;
  BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'jcustomer_delta_action_flag') THEN
        -- RAISE LOG 'execute procedure jcustomer_delta_action';
        CREATE TEMPORARY TABLE jcustomer_delta_action_flag ON COMMIT DROP AS (SELECT true as finish);
        IF EXISTS (SELECT WHERE false )
        THEN 
          RAISE check_violation USING MESSAGE = 'Invalid view update: constraints on the view are violated';
        END IF;
        IF EXISTS (SELECT  
FROM (SELECT  
FROM (SELECT   
WHERE NOT EXISTS ( SELECT * 
FROM public.nation AS nation_a3 
WHERE nation_a3.NAME = 'Japan' ) ) AS ⊥_a0_0  ) AS __dummy__ )
        THEN 
          RAISE check_violation USING MESSAGE = 'Invalid view update: constraints on the source relations are violated';
        END IF;
        CREATE TEMPORARY TABLE Δ_del_customer WITH OIDS ON COMMIT DROP AS SELECT (ROW(COL0,COL1,COL2,COL3,COL4) :: public.customer).* 
            FROM (SELECT Δ_del_customer_a5_0.COL0 AS COL0, Δ_del_customer_a5_0.COL1 AS COL1, Δ_del_customer_a5_0.COL2 AS COL2, Δ_del_customer_a5_0.COL3 AS COL3, Δ_del_customer_a5_0.COL4 AS COL4 
FROM (SELECT customer_a5_0.KEY AS COL0, customer_a5_0.NAME AS COL1, customer_a5_0.ADDRESS AS COL2, customer_a5_0.PHONE AS COL3, nation_a3_1.KEY AS COL4 
FROM public.customer AS customer_a5_0, public.nation AS nation_a3_1 
WHERE nation_a3_1.KEY = customer_a5_0.NATIONKEY AND nation_a3_1.NAME = 'Japan' AND NOT EXISTS ( SELECT * 
FROM (SELECT jcustomer_a3_0.KEY AS COL0, jcustomer_a3_0.NAME AS COL1, jcustomer_a3_0.ADDRESS AS COL2 
FROM public.jcustomer AS jcustomer_a3_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_jcustomer AS __temp__Δ_del_jcustomer_a3 
WHERE __temp__Δ_del_jcustomer_a3.ADDRESS = jcustomer_a3_0.ADDRESS AND __temp__Δ_del_jcustomer_a3.NAME = jcustomer_a3_0.NAME AND __temp__Δ_del_jcustomer_a3.KEY = jcustomer_a3_0.KEY )  UNION SELECT __temp__Δ_ins_jcustomer_a3_0.KEY AS COL0, __temp__Δ_ins_jcustomer_a3_0.NAME AS COL1, __temp__Δ_ins_jcustomer_a3_0.ADDRESS AS COL2 
FROM __temp__Δ_ins_jcustomer AS __temp__Δ_ins_jcustomer_a3_0  ) AS new_jcustomer_a3 
WHERE new_jcustomer_a3.COL2 = customer_a5_0.ADDRESS AND new_jcustomer_a3.COL1 = customer_a5_0.NAME AND new_jcustomer_a3.COL0 = customer_a5_0.KEY ) ) AS Δ_del_customer_a5_0  ) AS Δ_del_customer_extra_alias;

CREATE TEMPORARY TABLE Δ_ins_customer WITH OIDS ON COMMIT DROP AS SELECT (ROW(COL0,COL1,COL2,COL3,COL4) :: public.customer).* 
            FROM (SELECT Δ_ins_customer_a5_0.COL0 AS COL0, Δ_ins_customer_a5_0.COL1 AS COL1, Δ_ins_customer_a5_0.COL2 AS COL2, Δ_ins_customer_a5_0.COL3 AS COL3, Δ_ins_customer_a5_0.COL4 AS COL4 
FROM (SELECT customer_a5_2.KEY AS COL0, new_jcustomer_a3_0.COL1 AS COL1, new_jcustomer_a3_0.COL2 AS COL2, customer_a5_2.PHONE AS COL3, nation_a3_1.KEY AS COL4 
FROM (SELECT jcustomer_a3_0.KEY AS COL0, jcustomer_a3_0.NAME AS COL1, jcustomer_a3_0.ADDRESS AS COL2 
FROM public.jcustomer AS jcustomer_a3_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_jcustomer AS __temp__Δ_del_jcustomer_a3 
WHERE __temp__Δ_del_jcustomer_a3.ADDRESS = jcustomer_a3_0.ADDRESS AND __temp__Δ_del_jcustomer_a3.NAME = jcustomer_a3_0.NAME AND __temp__Δ_del_jcustomer_a3.KEY = jcustomer_a3_0.KEY )  UNION SELECT __temp__Δ_ins_jcustomer_a3_0.KEY AS COL0, __temp__Δ_ins_jcustomer_a3_0.NAME AS COL1, __temp__Δ_ins_jcustomer_a3_0.ADDRESS AS COL2 
FROM __temp__Δ_ins_jcustomer AS __temp__Δ_ins_jcustomer_a3_0  ) AS new_jcustomer_a3_0, public.nation AS nation_a3_1, public.customer AS customer_a5_2 
WHERE customer_a5_2.KEY = new_jcustomer_a3_0.COL0 AND nation_a3_1.NAME = 'Japan' AND NOT EXISTS ( SELECT * 
FROM (SELECT customer_a5_0.KEY AS COL0, customer_a5_0.NAME AS COL1, customer_a5_0.ADDRESS AS COL2 
FROM public.customer AS customer_a5_0, public.nation AS nation_a3_1 
WHERE nation_a3_1.KEY = customer_a5_0.NATIONKEY AND nation_a3_1.NAME = 'Japan' ) AS tmp_a3 
WHERE tmp_a3.COL2 = new_jcustomer_a3_0.COL2 AND tmp_a3.COL1 = new_jcustomer_a3_0.COL1 AND tmp_a3.COL0 = customer_a5_2.KEY )  UNION SELECT new_jcustomer_a3_0.COL0 AS COL0, new_jcustomer_a3_0.COL1 AS COL1, new_jcustomer_a3_0.COL2 AS COL2, 'unknown' AS COL3, nation_a3_1.KEY AS COL4 
FROM (SELECT jcustomer_a3_0.KEY AS COL0, jcustomer_a3_0.NAME AS COL1, jcustomer_a3_0.ADDRESS AS COL2 
FROM public.jcustomer AS jcustomer_a3_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_jcustomer AS __temp__Δ_del_jcustomer_a3 
WHERE __temp__Δ_del_jcustomer_a3.ADDRESS = jcustomer_a3_0.ADDRESS AND __temp__Δ_del_jcustomer_a3.NAME = jcustomer_a3_0.NAME AND __temp__Δ_del_jcustomer_a3.KEY = jcustomer_a3_0.KEY )  UNION SELECT __temp__Δ_ins_jcustomer_a3_0.KEY AS COL0, __temp__Δ_ins_jcustomer_a3_0.NAME AS COL1, __temp__Δ_ins_jcustomer_a3_0.ADDRESS AS COL2 
FROM __temp__Δ_ins_jcustomer AS __temp__Δ_ins_jcustomer_a3_0  ) AS new_jcustomer_a3_0, public.nation AS nation_a3_1 
WHERE nation_a3_1.NAME = 'Japan' AND NOT EXISTS ( SELECT * 
FROM (SELECT customer_a5_0.KEY AS COL0, customer_a5_0.NAME AS COL1, customer_a5_0.ADDRESS AS COL2 
FROM public.customer AS customer_a5_0, public.nation AS nation_a3_1 
WHERE nation_a3_1.KEY = customer_a5_0.NATIONKEY AND nation_a3_1.NAME = 'Japan' ) AS tmp_a3 
WHERE tmp_a3.COL2 = new_jcustomer_a3_0.COL2 AND tmp_a3.COL1 = new_jcustomer_a3_0.COL1 AND tmp_a3.COL0 = new_jcustomer_a3_0.COL0 ) AND NOT EXISTS ( SELECT * 
FROM public.customer AS customer_a5 
WHERE customer_a5.KEY = new_jcustomer_a3_0.COL0 ) ) AS Δ_ins_customer_a5_0  ) AS Δ_ins_customer_extra_alia 
            EXCEPT 
            SELECT * FROM  public.customer; 

FOR temprecΔ_del_customer IN ( SELECT * FROM Δ_del_customer) LOOP 
            DELETE FROM public.customer WHERE ROW(KEY,NAME,ADDRESS,PHONE,NATIONKEY) =  temprecΔ_del_customer;
            END LOOP;
DROP TABLE Δ_del_customer;

INSERT INTO public.customer (SELECT * FROM  Δ_ins_customer) ; 
DROP TABLE Δ_ins_customer;
        
        insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM __temp__Δ_ins_jcustomer) as t);
        IF insertion_data IS NOT DISTINCT FROM NULL THEN 
            insertion_data := '[]';
        END IF; 
        deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM __temp__Δ_del_jcustomer) as t);
        IF deletion_data IS NOT DISTINCT FROM NULL THEN 
            deletion_data := '[]';
        END IF; 
        IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
            user_name := (SELECT session_user);
            IF NOT (user_name = 'dejima') THEN 
                json_data := concat('{"view": ' , '"public.jcustomer"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
                result := public.jcustomer_run_shell(json_data);
                IF NOT (result = 'true') THEN
                    -- RAISE LOG 'result from running the sh script: %', result;
                    RAISE check_violation USING MESSAGE = 'update on view is rejected by the external tool, result from running the sh script: ' 
                    || result;
                END IF;
            ELSE 
                -- RAISE LOG 'function of detecting dejima update is called by % , no request sent to dejima proxy', user_name;

                -- update the table that stores the insertions and deletions we calculated
                DELETE FROM public.__dummy__jcustomer_detected_deletions;
                INSERT INTO public.__dummy__jcustomer_detected_deletions
                    SELECT * FROM __temp__Δ_del_jcustomer;

                DELETE FROM public.__dummy__jcustomer_detected_insertions;
                INSERT INTO public.__dummy__jcustomer_detected_insertions
                    SELECT * FROM __temp__Δ_ins_jcustomer;
            END IF;
        END IF;
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.jcustomer';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.jcustomer ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

CREATE OR REPLACE FUNCTION public.jcustomer_materialization()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
  BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = '__temp__Δ_ins_jcustomer' OR table_name = '__temp__Δ_del_jcustomer')
    THEN
        -- RAISE LOG 'execute procedure jcustomer_materialization';
        CREATE TEMPORARY TABLE __temp__Δ_ins_jcustomer ( LIKE public.jcustomer INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE CONSTRAINT TRIGGER __temp__jcustomer_trigger_delta_action
        AFTER INSERT OR UPDATE OR DELETE ON 
            __temp__Δ_ins_jcustomer DEFERRABLE INITIALLY DEFERRED 
            FOR EACH ROW EXECUTE PROCEDURE public.jcustomer_delta_action();

        CREATE TEMPORARY TABLE __temp__Δ_del_jcustomer ( LIKE public.jcustomer INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE CONSTRAINT TRIGGER __temp__jcustomer_trigger_delta_action
        AFTER INSERT OR UPDATE OR DELETE ON 
            __temp__Δ_del_jcustomer DEFERRABLE INITIALLY DEFERRED 
            FOR EACH ROW EXECUTE PROCEDURE public.jcustomer_delta_action();
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.jcustomer';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.jcustomer ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS jcustomer_trigger_materialization ON public.jcustomer;
CREATE TRIGGER jcustomer_trigger_materialization
    BEFORE INSERT OR UPDATE OR DELETE ON
      public.jcustomer FOR EACH STATEMENT EXECUTE PROCEDURE public.jcustomer_materialization();

CREATE OR REPLACE FUNCTION public.jcustomer_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
  BEGIN
    -- RAISE LOG 'execute procedure jcustomer_update';
    IF TG_OP = 'INSERT' THEN
      -- RAISE LOG 'NEW: %', NEW;
      IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update on view: view does not accept null value';
      END IF;
      DELETE FROM __temp__Δ_del_jcustomer WHERE ROW(KEY,NAME,ADDRESS) = NEW;
      INSERT INTO __temp__Δ_ins_jcustomer SELECT (NEW).*; 
    ELSIF TG_OP = 'UPDATE' THEN
      IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update on view: view does not accept null value';
      END IF;
      DELETE FROM __temp__Δ_ins_jcustomer WHERE ROW(KEY,NAME,ADDRESS) = OLD;
      INSERT INTO __temp__Δ_del_jcustomer SELECT (OLD).*;
      DELETE FROM __temp__Δ_del_jcustomer WHERE ROW(KEY,NAME,ADDRESS) = NEW;
      INSERT INTO __temp__Δ_ins_jcustomer SELECT (NEW).*; 
    ELSIF TG_OP = 'DELETE' THEN
      -- RAISE LOG 'OLD: %', OLD;
      DELETE FROM __temp__Δ_ins_jcustomer WHERE ROW(KEY,NAME,ADDRESS) = OLD;
      INSERT INTO __temp__Δ_del_jcustomer SELECT (OLD).*;
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.jcustomer';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.jcustomer ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS jcustomer_trigger_update ON public.jcustomer;
CREATE TRIGGER jcustomer_trigger_update
    INSTEAD OF INSERT OR UPDATE OR DELETE ON
      public.jcustomer FOR EACH ROW EXECUTE PROCEDURE public.jcustomer_update();

