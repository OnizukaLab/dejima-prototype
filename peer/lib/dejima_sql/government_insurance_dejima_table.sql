CREATE OR REPLACE VIEW public.dejima_insurance AS 
SELECT __dummy__.COL0 AS FIRST_NAME,__dummy__.COL1 AS LAST_NAME,__dummy__.COL2 AS ADDRESS,__dummy__.COL3 AS BIRTHDATE 
FROM (SELECT dejima_insurance_a4_0.COL0 AS COL0, dejima_insurance_a4_0.COL1 AS COL1, dejima_insurance_a4_0.COL2 AS COL2, dejima_insurance_a4_0.COL3 AS COL3 
FROM (SELECT government_users_a6_0.FIRST_NAME AS COL0, government_users_a6_0.LAST_NAME AS COL1, government_users_a6_0.ADDRESS AS COL2, government_users_a6_0.BIRTHDATE AS COL3 
FROM public.government_users AS government_users_a6_0  ) AS dejima_insurance_a4_0  ) AS __dummy__;

DROP MATERIALIZED VIEW IF EXISTS public.__dummy__materialized_dejima_insurance;

CREATE  MATERIALIZED VIEW public.__dummy__materialized_dejima_insurance AS 
SELECT * FROM public.dejima_insurance;

CREATE EXTENSION IF NOT EXISTS plsh;

CREATE OR REPLACE FUNCTION public.dejima_insurance_run_shell(text) RETURNS text AS $$
#!/bin/sh

result=$(curl -s -X POST -H "Content-Type: application/json" $DEJIMA_API_ENDPOINT -d "$1")
if  [ "$result" = "true" ];  then
    echo "true"
else 
    echo $result
    exit 1
fi
$$ LANGUAGE plsh;
CREATE OR REPLACE FUNCTION public.dejima_insurance_detect_update()
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
  IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'dejima_insurance_delta_action_flag') THEN
    insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM public.dejima_insurance EXCEPT SELECT * FROM public.__dummy__materialized_dejima_insurance) as t);
    IF insertion_data IS NOT DISTINCT FROM NULL THEN 
        insertion_data := '[]';
    END IF; 
    deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM public.__dummy__materialized_dejima_insurance EXCEPT SELECT * FROM public.dejima_insurance) as t);
    IF deletion_data IS NOT DISTINCT FROM NULL THEN 
        deletion_data := '[]';
    END IF; 
    IF (insertion_data IS DISTINCT FROM '[]') OR (insertion_data IS DISTINCT FROM '[]') THEN 
        user_name := (SELECT session_user);
        IF NOT (user_name = 'dejima') THEN 
            json_data := concat('{"view": ' , '"public.dejima_insurance"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
            result := public.dejima_insurance_run_shell(json_data);
            IF result = 'true' THEN 
                REFRESH MATERIALIZED VIEW public.__dummy__materialized_dejima_insurance;
                FOR func IN (select distinct trigger_schema||'.non_trigger_'||substring(action_statement, 19) as function 
                from information_schema.triggers where trigger_schema = 'public' and event_object_table='dejima_insurance'
                and action_timing='AFTER' and (event_manipulation='INSERT' or event_manipulation='DELETE' or event_manipulation='UPDATE')
                and action_statement like 'EXECUTE PROCEDURE %') 
                LOOP
                    EXECUTE 'SELECT ' || func into tv;
                END LOOP;
            ELSE
                -- RAISE LOG 'result from running the sh script: %', result;
                RAISE check_violation USING MESSAGE = 'update on view is rejected by the external tool, result from running the sh script: ' 
                || result;
            END IF;
        ELSE 
            RAISE LOG 'function of detecting dejima update is called by % , no request sent to dejima proxy', user_name;
        END IF;
    END IF;
  END IF;
  RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.dejima_insurance';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the function (non_trigger_)public.dejima_insurance_detect_update() ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

CREATE OR REPLACE FUNCTION public.non_trigger_dejima_insurance_detect_update()
RETURNS text 
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
  IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'dejima_insurance_delta_action_flag') THEN
    insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM public.dejima_insurance EXCEPT SELECT * FROM public.__dummy__materialized_dejima_insurance) as t);
    IF insertion_data IS NOT DISTINCT FROM NULL THEN 
        insertion_data := '[]';
    END IF; 
    deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM public.__dummy__materialized_dejima_insurance EXCEPT SELECT * FROM public.dejima_insurance) as t);
    IF deletion_data IS NOT DISTINCT FROM NULL THEN 
        deletion_data := '[]';
    END IF; 
    IF (insertion_data IS DISTINCT FROM '[]') OR (insertion_data IS DISTINCT FROM '[]') THEN 
        user_name := (SELECT session_user);
        IF NOT (user_name = 'dejima') THEN 
            json_data := concat('{"view": ' , '"public.dejima_insurance"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
            result := public.dejima_insurance_run_shell(json_data);
            IF result = 'true' THEN 
                REFRESH MATERIALIZED VIEW public.__dummy__materialized_dejima_insurance;
                FOR func IN (select distinct trigger_schema||'.non_trigger_'||substring(action_statement, 19) as function 
                from information_schema.triggers where trigger_schema = 'public' and event_object_table='dejima_insurance'
                and action_timing='AFTER' and (event_manipulation='INSERT' or event_manipulation='DELETE' or event_manipulation='UPDATE')
                and action_statement like 'EXECUTE PROCEDURE %') 
                LOOP
                    EXECUTE 'SELECT ' || func into tv;
                END LOOP;
            ELSE
                -- RAISE LOG 'result from running the sh script: %', result;
                RAISE check_violation USING MESSAGE = 'update on view is rejected by the external tool, result from running the sh script: ' 
                || result;
            END IF;
        ELSE 
            RAISE LOG 'function of detecting dejima update is called by % , no request sent to dejima proxy', user_name;
        END IF;
    END IF;
  END IF;
  RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.dejima_insurance';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the function (non_trigger_)public.dejima_insurance_detect_update() ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS government_users_detect_update_dejima_insurance ON public.government_users;
        CREATE TRIGGER government_users_detect_update_dejima_insurance
            AFTER INSERT OR UPDATE OR DELETE ON
            public.government_users FOR EACH STATEMENT EXECUTE PROCEDURE public.dejima_insurance_detect_update();

CREATE OR REPLACE FUNCTION public.dejima_insurance_delta_action()
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
  temprecΔ_del_government_users public.government_users%ROWTYPE;
temprecΔ_ins_government_users public.government_users%ROWTYPE;
  BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'dejima_insurance_delta_action_flag') THEN
        -- RAISE LOG 'execute procedure dejima_insurance_delta_action';
        CREATE TEMPORARY TABLE dejima_insurance_delta_action_flag ON COMMIT DROP AS (SELECT true as finish);
        IF EXISTS (SELECT WHERE false )
        THEN 
          RAISE check_violation USING MESSAGE = 'Invalid view update: constraints on the view are violated';
        END IF;
        IF EXISTS (SELECT WHERE false )
        THEN 
          RAISE check_violation USING MESSAGE = 'Invalid view update: constraints on the source relations are violated';
        END IF;
        CREATE TEMPORARY TABLE Δ_del_government_users WITH OIDS ON COMMIT DROP AS SELECT (ROW(COL0,COL1,COL2,COL3,COL4,COL5) :: public.government_users).* 
            FROM (SELECT Δ_del_government_users_a6_0.COL0 AS COL0, Δ_del_government_users_a6_0.COL1 AS COL1, Δ_del_government_users_a6_0.COL2 AS COL2, Δ_del_government_users_a6_0.COL3 AS COL3, Δ_del_government_users_a6_0.COL4 AS COL4, Δ_del_government_users_a6_0.COL5 AS COL5 
FROM (SELECT government_users_a6_0.ID AS COL0, government_users_a6_0.FIRST_NAME AS COL1, government_users_a6_0.LAST_NAME AS COL2, government_users_a6_0.PHONE AS COL3, government_users_a6_0.ADDRESS AS COL4, government_users_a6_0.BIRTHDATE AS COL5 
FROM public.government_users AS government_users_a6_0 
WHERE NOT EXISTS ( SELECT * 
FROM (SELECT dejima_insurance_a4_0.FIRST_NAME AS COL0, dejima_insurance_a4_0.LAST_NAME AS COL1, dejima_insurance_a4_0.ADDRESS AS COL2, dejima_insurance_a4_0.BIRTHDATE AS COL3 
FROM public.dejima_insurance AS dejima_insurance_a4_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_dejima_insurance AS __temp__Δ_del_dejima_insurance_a4 
WHERE __temp__Δ_del_dejima_insurance_a4.BIRTHDATE = dejima_insurance_a4_0.BIRTHDATE AND __temp__Δ_del_dejima_insurance_a4.ADDRESS = dejima_insurance_a4_0.ADDRESS AND __temp__Δ_del_dejima_insurance_a4.LAST_NAME = dejima_insurance_a4_0.LAST_NAME AND __temp__Δ_del_dejima_insurance_a4.FIRST_NAME = dejima_insurance_a4_0.FIRST_NAME )  UNION SELECT __temp__Δ_ins_dejima_insurance_a4_0.FIRST_NAME AS COL0, __temp__Δ_ins_dejima_insurance_a4_0.LAST_NAME AS COL1, __temp__Δ_ins_dejima_insurance_a4_0.ADDRESS AS COL2, __temp__Δ_ins_dejima_insurance_a4_0.BIRTHDATE AS COL3 
FROM __temp__Δ_ins_dejima_insurance AS __temp__Δ_ins_dejima_insurance_a4_0  ) AS new_dejima_insurance_a4 
WHERE new_dejima_insurance_a4.COL3 = government_users_a6_0.BIRTHDATE AND new_dejima_insurance_a4.COL2 = government_users_a6_0.ADDRESS AND new_dejima_insurance_a4.COL1 = government_users_a6_0.LAST_NAME AND new_dejima_insurance_a4.COL0 = government_users_a6_0.FIRST_NAME ) ) AS Δ_del_government_users_a6_0  ) AS Δ_del_government_users_extra_alias;

CREATE TEMPORARY TABLE Δ_ins_government_users WITH OIDS ON COMMIT DROP AS SELECT (ROW(COL0,COL1,COL2,COL3,COL4,COL5) :: public.government_users).* 
            FROM (SELECT Δ_ins_government_users_a6_0.COL0 AS COL0, Δ_ins_government_users_a6_0.COL1 AS COL1, Δ_ins_government_users_a6_0.COL2 AS COL2, Δ_ins_government_users_a6_0.COL3 AS COL3, Δ_ins_government_users_a6_0.COL4 AS COL4, Δ_ins_government_users_a6_0.COL5 AS COL5 
FROM (SELECT current_max_id_a1_1.COL0+1 AS COL0, new_dejima_insurance_a4_0.COL0 AS COL1, new_dejima_insurance_a4_0.COL1 AS COL2, 'unknown' AS COL3, new_dejima_insurance_a4_0.COL2 AS COL4, new_dejima_insurance_a4_0.COL3 AS COL5 
FROM (SELECT dejima_insurance_a4_0.FIRST_NAME AS COL0, dejima_insurance_a4_0.LAST_NAME AS COL1, dejima_insurance_a4_0.ADDRESS AS COL2, dejima_insurance_a4_0.BIRTHDATE AS COL3 
FROM public.dejima_insurance AS dejima_insurance_a4_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_dejima_insurance AS __temp__Δ_del_dejima_insurance_a4 
WHERE __temp__Δ_del_dejima_insurance_a4.BIRTHDATE = dejima_insurance_a4_0.BIRTHDATE AND __temp__Δ_del_dejima_insurance_a4.ADDRESS = dejima_insurance_a4_0.ADDRESS AND __temp__Δ_del_dejima_insurance_a4.LAST_NAME = dejima_insurance_a4_0.LAST_NAME AND __temp__Δ_del_dejima_insurance_a4.FIRST_NAME = dejima_insurance_a4_0.FIRST_NAME )  UNION SELECT __temp__Δ_ins_dejima_insurance_a4_0.FIRST_NAME AS COL0, __temp__Δ_ins_dejima_insurance_a4_0.LAST_NAME AS COL1, __temp__Δ_ins_dejima_insurance_a4_0.ADDRESS AS COL2, __temp__Δ_ins_dejima_insurance_a4_0.BIRTHDATE AS COL3 
FROM __temp__Δ_ins_dejima_insurance AS __temp__Δ_ins_dejima_insurance_a4_0  ) AS new_dejima_insurance_a4_0, (SELECT MAX(all_ids_a1_0.COL0) AS COL0 
FROM (SELECT 0 AS COL0    UNION SELECT government_users_a6_0.ID AS COL0 
FROM public.government_users AS government_users_a6_0  ) AS all_ids_a1_0   ) AS current_max_id_a1_1 
WHERE NOT EXISTS ( SELECT * 
FROM public.government_users AS government_users_a6 
WHERE government_users_a6.BIRTHDATE = new_dejima_insurance_a4_0.COL3 AND government_users_a6.ADDRESS = new_dejima_insurance_a4_0.COL2 AND government_users_a6.LAST_NAME = new_dejima_insurance_a4_0.COL1 AND government_users_a6.FIRST_NAME = new_dejima_insurance_a4_0.COL0 ) ) AS Δ_ins_government_users_a6_0  ) AS Δ_ins_government_users_extra_alia 
            EXCEPT 
            SELECT * FROM  public.government_users; 

FOR temprecΔ_del_government_users IN ( SELECT * FROM Δ_del_government_users) LOOP 
            DELETE FROM public.government_users WHERE ROW(ID,FIRST_NAME,LAST_NAME,PHONE,ADDRESS,BIRTHDATE) =  temprecΔ_del_government_users;
            END LOOP;
DROP TABLE Δ_del_government_users;

INSERT INTO public.government_users (SELECT * FROM  Δ_ins_government_users) ; 
DROP TABLE Δ_ins_government_users;
        
        insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM __temp__Δ_ins_dejima_insurance EXCEPT SELECT * FROM public.__dummy__materialized_dejima_insurance) as t);
        IF insertion_data IS NOT DISTINCT FROM NULL THEN 
            insertion_data := '[]';
        END IF; 
        deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM __temp__Δ_del_dejima_insurance INTERSECT SELECT * FROM public.__dummy__materialized_dejima_insurance) as t);
        IF deletion_data IS NOT DISTINCT FROM NULL THEN 
            deletion_data := '[]';
        END IF; 
        IF (insertion_data IS DISTINCT FROM '[]') OR (insertion_data IS DISTINCT FROM '[]') THEN 
            user_name := (SELECT session_user);
            IF NOT (user_name = 'dejima') THEN 
                json_data := concat('{"view": ' , '"public.dejima_insurance"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
                result := public.dejima_insurance_run_shell(json_data);
                IF result = 'true' THEN 
                    REFRESH MATERIALIZED VIEW public.__dummy__materialized_dejima_insurance;
                ELSE
                    -- RAISE LOG 'result from running the sh script: %', result;
                    RAISE check_violation USING MESSAGE = 'update on view is rejected by the external tool, result from running the sh script: ' 
                    || result;
                END IF;
            ELSE 
                RAISE LOG 'function of detecting dejima update is called by % , no request sent to dejima proxy', user_name;
            END IF;
        END IF;
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.dejima_insurance';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.dejima_insurance ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

CREATE OR REPLACE FUNCTION public.dejima_insurance_materialization()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
  BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = '__temp__Δ_ins_dejima_insurance' OR table_name = '__temp__Δ_del_dejima_insurance')
    THEN
        -- RAISE LOG 'execute procedure dejima_insurance_materialization';
        CREATE TEMPORARY TABLE __temp__Δ_ins_dejima_insurance ( LIKE public.dejima_insurance INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE CONSTRAINT TRIGGER __temp__dejima_insurance_trigger_delta_action
        AFTER INSERT OR UPDATE OR DELETE ON 
            __temp__Δ_ins_dejima_insurance DEFERRABLE INITIALLY DEFERRED 
            FOR EACH ROW EXECUTE PROCEDURE public.dejima_insurance_delta_action();

        CREATE TEMPORARY TABLE __temp__Δ_del_dejima_insurance ( LIKE public.dejima_insurance INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE CONSTRAINT TRIGGER __temp__dejima_insurance_trigger_delta_action
        AFTER INSERT OR UPDATE OR DELETE ON 
            __temp__Δ_del_dejima_insurance DEFERRABLE INITIALLY DEFERRED 
            FOR EACH ROW EXECUTE PROCEDURE public.dejima_insurance_delta_action();
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.dejima_insurance';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.dejima_insurance ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS dejima_insurance_trigger_materialization ON public.dejima_insurance;
CREATE TRIGGER dejima_insurance_trigger_materialization
    BEFORE INSERT OR UPDATE OR DELETE ON
      public.dejima_insurance FOR EACH STATEMENT EXECUTE PROCEDURE public.dejima_insurance_materialization();

CREATE OR REPLACE FUNCTION public.dejima_insurance_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
  BEGIN
    -- RAISE LOG 'execute procedure dejima_insurance_update';
    IF TG_OP = 'INSERT' THEN
      -- RAISE LOG 'NEW: %', NEW;
      IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update on view: view does not accept null value';
      END IF;
      DELETE FROM __temp__Δ_del_dejima_insurance WHERE ROW(FIRST_NAME,LAST_NAME,ADDRESS,BIRTHDATE) = NEW;
      INSERT INTO __temp__Δ_ins_dejima_insurance SELECT (NEW).*; 
    ELSIF TG_OP = 'UPDATE' THEN
      IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update on view: view does not accept null value';
      END IF;
      DELETE FROM __temp__Δ_ins_dejima_insurance WHERE ROW(FIRST_NAME,LAST_NAME,ADDRESS,BIRTHDATE) = OLD;
      INSERT INTO __temp__Δ_del_dejima_insurance SELECT (OLD).*;
      DELETE FROM __temp__Δ_del_dejima_insurance WHERE ROW(FIRST_NAME,LAST_NAME,ADDRESS,BIRTHDATE) = NEW;
      INSERT INTO __temp__Δ_ins_dejima_insurance SELECT (NEW).*; 
    ELSIF TG_OP = 'DELETE' THEN
      -- RAISE LOG 'OLD: %', OLD;
      DELETE FROM __temp__Δ_ins_dejima_insurance WHERE ROW(FIRST_NAME,LAST_NAME,ADDRESS,BIRTHDATE) = OLD;
      INSERT INTO __temp__Δ_del_dejima_insurance SELECT (OLD).*;
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.dejima_insurance';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.dejima_insurance ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS dejima_insurance_trigger_update ON public.dejima_insurance;
CREATE TRIGGER dejima_insurance_trigger_update
    INSTEAD OF INSERT OR UPDATE OR DELETE ON
      public.dejima_insurance FOR EACH ROW EXECUTE PROCEDURE public.dejima_insurance_update();

-- dejima_insurance(FIRST_NAME, LAST_NAME, ADDRESS, BIRTHDATE) :- government_users(_, FIRST_NAME, LAST_NAME, _, ADDRESS, BIRTHDATE).

CREATE OR REPLACE FUNCTION public.dejima_insurance_col2col_mapping()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  mappping text;
  BEGIN
    mappping = 
'{
  dejima_insurance.FIRST_NAME: government_users.FIRST_NAME,
  dejima_insurance.LAST_NAME: government_users.LAST_NAME,
  dejima_insurance.ADDRESS: government_users.ADDRESS,
  dejima_insurance.BIRTHDATE: government_users.BIRTHDATE
}';
    RETURN mappping;
  END;
$$;
