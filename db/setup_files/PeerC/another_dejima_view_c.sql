
/*view definition (get):
another_dejima_view(KEY, NAME) :- p_0(KEY, NAME).
p_0(KEY, NAME) :- customer(KEY, NAME).
*/

CREATE OR REPLACE VIEW public.another_dejima_view AS 
SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME 
FROM (SELECT another_dejima_view_a2_0.COL0 AS COL0, another_dejima_view_a2_0.COL1 AS COL1 
FROM (SELECT p_0_a2_0.COL0 AS COL0, p_0_a2_0.COL1 AS COL1 
FROM (SELECT customer_a2_0.KEY AS COL0, customer_a2_0.NAME AS COL1 
FROM public.customer AS customer_a2_0  ) AS p_0_a2_0  ) AS another_dejima_view_a2_0  ) AS __dummy__;

CREATE EXTENSION IF NOT EXISTS plsh;

CREATE TABLE public.__dummy__another_dejima_view_detected_deletions ( LIKE public.another_dejima_view INCLUDING ALL );
CREATE TABLE public.__dummy__another_dejima_view_detected_insertions ( LIKE public.another_dejima_view INCLUDING ALL );

CREATE OR REPLACE FUNCTION public.another_dejima_view_get_detected_update_data()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  deletion_data text;
  insertion_data text;
  json_data text;
  BEGIN
    insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM public.__dummy__another_dejima_view_detected_insertions as t);
    IF insertion_data IS NOT DISTINCT FROM NULL THEN 
        insertion_data := '[]';
    END IF; 
    deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM public.__dummy__another_dejima_view_detected_deletions as t);
    IF deletion_data IS NOT DISTINCT FROM NULL THEN 
        deletion_data := '[]';
    END IF; 
    IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
        -- calcuate the update data
        json_data := concat('{"view": ' , '"public.another_dejima_view"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
        -- clear the update data
        DELETE FROM public.__dummy__another_dejima_view_detected_deletions;
        DELETE FROM public.__dummy__another_dejima_view_detected_insertions;
    END IF;
    RETURN json_data;
  END;
$$;

CREATE OR REPLACE FUNCTION public.another_dejima_view_run_shell(text) RETURNS text AS $$
#!/bin/sh
echo "true"
$$ LANGUAGE plsh;

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
    DELETE FROM __temp__Δ_del_customer WHERE ROW(KEY,NAME) = NEW;
    INSERT INTO __temp__Δ_ins_customer SELECT (NEW).*; 
    ELSIF TG_OP = 'UPDATE' THEN
    IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update: null value is not accepted';
    END IF;
    DELETE FROM __temp__Δ_ins_customer WHERE ROW(KEY,NAME) = OLD;
    INSERT INTO __temp__Δ_del_customer SELECT (OLD).*;
    DELETE FROM __temp__Δ_del_customer WHERE ROW(KEY,NAME) = NEW;
    INSERT INTO __temp__Δ_ins_customer SELECT (NEW).*; 
    ELSIF TG_OP = 'DELETE' THEN
    -- RAISE LOG 'OLD: %', OLD;
    DELETE FROM __temp__Δ_ins_customer WHERE ROW(KEY,NAME) = OLD;
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

CREATE OR REPLACE FUNCTION public.customer_detect_update_on_another_dejima_view()
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
IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'another_dejima_view_delta_action_flag') THEN
    insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME 
FROM (SELECT ∂_ins_another_dejima_view_a2_0.COL0 AS COL0, ∂_ins_another_dejima_view_a2_0.COL1 AS COL1 
FROM (SELECT p_0_a2_0.COL0 AS COL0, p_0_a2_0.COL1 AS COL1 
FROM (SELECT __temp__Δ_ins_customer_a2_0.KEY AS COL0, __temp__Δ_ins_customer_a2_0.NAME AS COL1 
FROM __temp__Δ_ins_customer AS __temp__Δ_ins_customer_a2_0  ) AS p_0_a2_0  ) AS ∂_ins_another_dejima_view_a2_0  ) AS __dummy__) as t);
    IF insertion_data IS NOT DISTINCT FROM NULL THEN 
        insertion_data := '[]';
    END IF; 
    deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME 
FROM (SELECT ∂_del_another_dejima_view_a2_0.COL0 AS COL0, ∂_del_another_dejima_view_a2_0.COL1 AS COL1 
FROM (SELECT p_0_a2_0.COL0 AS COL0, p_0_a2_0.COL1 AS COL1 
FROM (SELECT __temp__Δ_del_customer_a2_0.KEY AS COL0, __temp__Δ_del_customer_a2_0.NAME AS COL1 
FROM __temp__Δ_del_customer AS __temp__Δ_del_customer_a2_0  ) AS p_0_a2_0  ) AS ∂_del_another_dejima_view_a2_0  ) AS __dummy__) as t);
    IF deletion_data IS NOT DISTINCT FROM NULL THEN 
        deletion_data := '[]';
    END IF; 
    IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
        user_name := (SELECT session_user);
        IF NOT (user_name = 'dejima') THEN 
            json_data := concat('{"view": ' , '"public.another_dejima_view"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
            result := public.another_dejima_view_run_shell(json_data);
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
            RAISE LOG 'function of detecting dejima update is called by % , no request sent to dejima proxy', user_name;

            -- update the table that stores the insertions and deletions we calculated
            DELETE FROM public.__dummy__another_dejima_view_detected_deletions;
            INSERT INTO public.__dummy__another_dejima_view_detected_deletions
                SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME 
FROM (SELECT ∂_del_another_dejima_view_a2_0.COL0 AS COL0, ∂_del_another_dejima_view_a2_0.COL1 AS COL1 
FROM (SELECT p_0_a2_0.COL0 AS COL0, p_0_a2_0.COL1 AS COL1 
FROM (SELECT __temp__Δ_del_customer_a2_0.KEY AS COL0, __temp__Δ_del_customer_a2_0.NAME AS COL1 
FROM __temp__Δ_del_customer AS __temp__Δ_del_customer_a2_0  ) AS p_0_a2_0  ) AS ∂_del_another_dejima_view_a2_0  ) AS __dummy__;

            DELETE FROM public.__dummy__another_dejima_view_detected_insertions;
            INSERT INTO public.__dummy__another_dejima_view_detected_insertions
                SELECT __dummy__.COL0 AS KEY,__dummy__.COL1 AS NAME 
FROM (SELECT ∂_ins_another_dejima_view_a2_0.COL0 AS COL0, ∂_ins_another_dejima_view_a2_0.COL1 AS COL1 
FROM (SELECT p_0_a2_0.COL0 AS COL0, p_0_a2_0.COL1 AS COL1 
FROM (SELECT __temp__Δ_ins_customer_a2_0.KEY AS COL0, __temp__Δ_ins_customer_a2_0.NAME AS COL1 
FROM __temp__Δ_ins_customer AS __temp__Δ_ins_customer_a2_0  ) AS p_0_a2_0  ) AS ∂_ins_another_dejima_view_a2_0  ) AS __dummy__;
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
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the function public.customer_detect_update_on_another_dejima_view() ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS customer_detect_update_on_another_dejima_view ON public.customer;
CREATE TRIGGER customer_detect_update_on_another_dejima_view
    AFTER INSERT OR UPDATE OR DELETE ON
    public.customer FOR EACH STATEMENT EXECUTE PROCEDURE public.customer_detect_update_on_another_dejima_view();



CREATE OR REPLACE FUNCTION public.another_dejima_view_delta_action()
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
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'another_dejima_view_delta_action_flag') THEN
        -- RAISE LOG 'execute procedure another_dejima_view_delta_action';
        CREATE TEMPORARY TABLE another_dejima_view_delta_action_flag ON COMMIT DROP AS (SELECT true as finish);
        IF EXISTS (SELECT WHERE false )
        THEN 
          RAISE check_violation USING MESSAGE = 'Invalid view update: constraints on the view are violated';
        END IF;
        IF EXISTS (SELECT WHERE false )
        THEN 
          RAISE check_violation USING MESSAGE = 'Invalid view update: constraints on the source relations are violated';
        END IF;
        CREATE TEMPORARY TABLE Δ_del_customer WITH OIDS ON COMMIT DROP AS SELECT (ROW(COL0,COL1) :: public.customer).* 
            FROM (SELECT Δ_del_customer_a2_0.COL0 AS COL0, Δ_del_customer_a2_0.COL1 AS COL1 
FROM (SELECT customer_a2_0.KEY AS COL0, customer_a2_0.NAME AS COL1 
FROM public.customer AS customer_a2_0 
WHERE NOT EXISTS ( SELECT * 
FROM (SELECT another_dejima_view_a2_0.KEY AS COL0, another_dejima_view_a2_0.NAME AS COL1 
FROM public.another_dejima_view AS another_dejima_view_a2_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_another_dejima_view AS __temp__Δ_del_another_dejima_view_a2 
WHERE __temp__Δ_del_another_dejima_view_a2.NAME = another_dejima_view_a2_0.NAME AND __temp__Δ_del_another_dejima_view_a2.KEY = another_dejima_view_a2_0.KEY )  UNION SELECT __temp__Δ_ins_another_dejima_view_a2_0.KEY AS COL0, __temp__Δ_ins_another_dejima_view_a2_0.NAME AS COL1 
FROM __temp__Δ_ins_another_dejima_view AS __temp__Δ_ins_another_dejima_view_a2_0  ) AS new_another_dejima_view_a2 
WHERE new_another_dejima_view_a2.COL1 = customer_a2_0.NAME AND new_another_dejima_view_a2.COL0 = customer_a2_0.KEY ) ) AS Δ_del_customer_a2_0  ) AS Δ_del_customer_extra_alias;

CREATE TEMPORARY TABLE Δ_ins_customer WITH OIDS ON COMMIT DROP AS SELECT (ROW(COL0,COL1) :: public.customer).* 
            FROM (SELECT Δ_ins_customer_a2_0.COL0 AS COL0, Δ_ins_customer_a2_0.COL1 AS COL1 
FROM (SELECT new_another_dejima_view_a2_0.COL0 AS COL0, new_another_dejima_view_a2_0.COL1 AS COL1 
FROM (SELECT another_dejima_view_a2_0.KEY AS COL0, another_dejima_view_a2_0.NAME AS COL1 
FROM public.another_dejima_view AS another_dejima_view_a2_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_another_dejima_view AS __temp__Δ_del_another_dejima_view_a2 
WHERE __temp__Δ_del_another_dejima_view_a2.NAME = another_dejima_view_a2_0.NAME AND __temp__Δ_del_another_dejima_view_a2.KEY = another_dejima_view_a2_0.KEY )  UNION SELECT __temp__Δ_ins_another_dejima_view_a2_0.KEY AS COL0, __temp__Δ_ins_another_dejima_view_a2_0.NAME AS COL1 
FROM __temp__Δ_ins_another_dejima_view AS __temp__Δ_ins_another_dejima_view_a2_0  ) AS new_another_dejima_view_a2_0 
WHERE NOT EXISTS ( SELECT * 
FROM public.customer AS customer_a2 
WHERE customer_a2.NAME = new_another_dejima_view_a2_0.COL1 AND customer_a2.KEY = new_another_dejima_view_a2_0.COL0 ) ) AS Δ_ins_customer_a2_0  ) AS Δ_ins_customer_extra_alia 
            EXCEPT 
            SELECT * FROM  public.customer; 

FOR temprecΔ_del_customer IN ( SELECT * FROM Δ_del_customer) LOOP 
            DELETE FROM public.customer WHERE ROW(KEY,NAME) =  temprecΔ_del_customer;
            END LOOP;
DROP TABLE Δ_del_customer;

INSERT INTO public.customer (SELECT * FROM  Δ_ins_customer) ; 
DROP TABLE Δ_ins_customer;
        
        insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM __temp__Δ_ins_another_dejima_view) as t);
        IF insertion_data IS NOT DISTINCT FROM NULL THEN 
            insertion_data := '[]';
        END IF; 
        deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM __temp__Δ_del_another_dejima_view) as t);
        IF deletion_data IS NOT DISTINCT FROM NULL THEN 
            deletion_data := '[]';
        END IF; 
        IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
            user_name := (SELECT session_user);
            IF NOT (user_name = 'dejima') THEN 
                json_data := concat('{"view": ' , '"public.another_dejima_view"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
                result := public.another_dejima_view_run_shell(json_data);
                IF NOT (result = 'true') THEN
                    -- RAISE LOG 'result from running the sh script: %', result;
                    RAISE check_violation USING MESSAGE = 'update on view is rejected by the external tool, result from running the sh script: ' 
                    || result;
                END IF;
            ELSE 
                RAISE LOG 'function of detecting dejima update is called by % , no request sent to dejima proxy', user_name;

                -- update the table that stores the insertions and deletions we calculated
                DELETE FROM public.__dummy__another_dejima_view_detected_deletions;
                INSERT INTO public.__dummy__another_dejima_view_detected_deletions
                    SELECT * FROM __temp__Δ_del_another_dejima_view;

                DELETE FROM public.__dummy__another_dejima_view_detected_insertions;
                INSERT INTO public.__dummy__another_dejima_view_detected_insertions
                    SELECT * FROM __temp__Δ_ins_another_dejima_view;
            END IF;
        END IF;
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.another_dejima_view';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.another_dejima_view ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

CREATE OR REPLACE FUNCTION public.another_dejima_view_materialization()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
  BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = '__temp__Δ_ins_another_dejima_view' OR table_name = '__temp__Δ_del_another_dejima_view')
    THEN
        -- RAISE LOG 'execute procedure another_dejima_view_materialization';
        CREATE TEMPORARY TABLE __temp__Δ_ins_another_dejima_view ( LIKE public.another_dejima_view INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE CONSTRAINT TRIGGER __temp__another_dejima_view_trigger_delta_action
        AFTER INSERT OR UPDATE OR DELETE ON 
            __temp__Δ_ins_another_dejima_view DEFERRABLE INITIALLY DEFERRED 
            FOR EACH ROW EXECUTE PROCEDURE public.another_dejima_view_delta_action();

        CREATE TEMPORARY TABLE __temp__Δ_del_another_dejima_view ( LIKE public.another_dejima_view INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE CONSTRAINT TRIGGER __temp__another_dejima_view_trigger_delta_action
        AFTER INSERT OR UPDATE OR DELETE ON 
            __temp__Δ_del_another_dejima_view DEFERRABLE INITIALLY DEFERRED 
            FOR EACH ROW EXECUTE PROCEDURE public.another_dejima_view_delta_action();
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.another_dejima_view';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.another_dejima_view ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS another_dejima_view_trigger_materialization ON public.another_dejima_view;
CREATE TRIGGER another_dejima_view_trigger_materialization
    BEFORE INSERT OR UPDATE OR DELETE ON
      public.another_dejima_view FOR EACH STATEMENT EXECUTE PROCEDURE public.another_dejima_view_materialization();

CREATE OR REPLACE FUNCTION public.another_dejima_view_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
  BEGIN
    -- RAISE LOG 'execute procedure another_dejima_view_update';
    IF TG_OP = 'INSERT' THEN
      -- RAISE LOG 'NEW: %', NEW;
      IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update on view: view does not accept null value';
      END IF;
      DELETE FROM __temp__Δ_del_another_dejima_view WHERE ROW(KEY,NAME) = NEW;
      INSERT INTO __temp__Δ_ins_another_dejima_view SELECT (NEW).*; 
    ELSIF TG_OP = 'UPDATE' THEN
      IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update on view: view does not accept null value';
      END IF;
      DELETE FROM __temp__Δ_ins_another_dejima_view WHERE ROW(KEY,NAME) = OLD;
      INSERT INTO __temp__Δ_del_another_dejima_view SELECT (OLD).*;
      DELETE FROM __temp__Δ_del_another_dejima_view WHERE ROW(KEY,NAME) = NEW;
      INSERT INTO __temp__Δ_ins_another_dejima_view SELECT (NEW).*; 
    ELSIF TG_OP = 'DELETE' THEN
      -- RAISE LOG 'OLD: %', OLD;
      DELETE FROM __temp__Δ_ins_another_dejima_view WHERE ROW(KEY,NAME) = OLD;
      INSERT INTO __temp__Δ_del_another_dejima_view SELECT (OLD).*;
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.another_dejima_view';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.another_dejima_view ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS another_dejima_view_trigger_update ON public.another_dejima_view;
CREATE TRIGGER another_dejima_view_trigger_update
    INSTEAD OF INSERT OR UPDATE OR DELETE ON
      public.another_dejima_view FOR EACH ROW EXECUTE PROCEDURE public.another_dejima_view_update();

