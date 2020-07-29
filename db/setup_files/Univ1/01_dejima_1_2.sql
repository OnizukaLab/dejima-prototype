CREATE OR REPLACE VIEW public.dejima_1_2 AS 
SELECT __dummy__.COL0 AS ID,__dummy__.COL1 AS UNIVERSITY,__dummy__.COL2 AS FIRST_NAME,__dummy__.COL3 AS LAST_NAME 
FROM (SELECT dejima_1_2_a4_0.COL0 AS COL0, dejima_1_2_a4_0.COL1 AS COL1, dejima_1_2_a4_0.COL2 AS COL2, dejima_1_2_a4_0.COL3 AS COL3 
FROM (SELECT student_a4_0.ID AS COL0, student_a4_0.UNIVERSITY AS COL1, student_a4_0.FIRST_NAME AS COL2, student_a4_0.LAST_NAME AS COL3 
FROM public.student AS student_a4_0 
WHERE student_a4_0.UNIVERSITY  <>  'Univ3' ) AS dejima_1_2_a4_0  ) AS __dummy__;

CREATE EXTENSION IF NOT EXISTS plsh;

CREATE TABLE public.__dummy__dejima_1_2_detected_deletions ( LIKE public.dejima_1_2 INCLUDING ALL );
CREATE TABLE public.__dummy__dejima_1_2_detected_insertions ( LIKE public.dejima_1_2 INCLUDING ALL );

CREATE OR REPLACE FUNCTION public.dejima_1_2_get_detected_update_data()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  deletion_data text;
  insertion_data text;
  json_data text;
  BEGIN
    insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM public.__dummy__dejima_1_2_detected_insertions as t);
    IF insertion_data IS NOT DISTINCT FROM NULL THEN 
        insertion_data := '[]';
    END IF; 
    deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM public.__dummy__dejima_1_2_detected_deletions as t);
    IF deletion_data IS NOT DISTINCT FROM NULL THEN 
        deletion_data := '[]';
    END IF; 
    IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
        -- calcuate the update data
        json_data := concat('{"view": ' , '"public.dejima_1_2"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
        -- clear the update data
        DELETE FROM public.__dummy__dejima_1_2_detected_deletions;
        DELETE FROM public.__dummy__dejima_1_2_detected_insertions;
    END IF;
    RETURN json_data;
  END;
$$;

CREATE OR REPLACE FUNCTION public.dejima_1_2_run_shell(text) RETURNS text AS $$
#!/bin/sh
echo "true"
$$ LANGUAGE plsh;

CREATE OR REPLACE FUNCTION public.student_materialization()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
text_var1 text;
text_var2 text;
text_var3 text;
BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = '__temp__Δ_ins_student' OR table_name = '__temp__Δ_del_student')
    THEN
        -- RAISE LOG 'execute procedure student_materialization';
        CREATE TEMPORARY TABLE __temp__Δ_ins_student ( LIKE public.student INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE TEMPORARY TABLE __temp__Δ_del_student ( LIKE public.student INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE TEMPORARY TABLE __temp__student WITH OIDS ON COMMIT DROP AS (SELECT * FROM public.student);
        
    END IF;
    RETURN NULL;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to public.student';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.student ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS student_trigger_materialization ON public.student;
CREATE TRIGGER student_trigger_materialization
    BEFORE INSERT OR UPDATE OR DELETE ON
    public.student FOR EACH STATEMENT EXECUTE PROCEDURE public.student_materialization();

CREATE OR REPLACE FUNCTION public.student_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
text_var1 text;
text_var2 text;
text_var3 text;
BEGIN
    -- RAISE LOG 'execute procedure student_update';
    IF TG_OP = 'INSERT' THEN
    -- RAISE LOG 'NEW: %', NEW;
    IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update: null value is not accepted';
    END IF;
    DELETE FROM __temp__Δ_del_student WHERE ROW(ID,UNIVERSITY,FIRST_NAME,LAST_NAME) = NEW;
    INSERT INTO __temp__Δ_ins_student SELECT (NEW).*; 
    ELSIF TG_OP = 'UPDATE' THEN
    IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update: null value is not accepted';
    END IF;
    DELETE FROM __temp__Δ_ins_student WHERE ROW(ID,UNIVERSITY,FIRST_NAME,LAST_NAME) = OLD;
    INSERT INTO __temp__Δ_del_student SELECT (OLD).*;
    DELETE FROM __temp__Δ_del_student WHERE ROW(ID,UNIVERSITY,FIRST_NAME,LAST_NAME) = NEW;
    INSERT INTO __temp__Δ_ins_student SELECT (NEW).*; 
    ELSIF TG_OP = 'DELETE' THEN
    -- RAISE LOG 'OLD: %', OLD;
    DELETE FROM __temp__Δ_ins_student WHERE ROW(ID,UNIVERSITY,FIRST_NAME,LAST_NAME) = OLD;
    INSERT INTO __temp__Δ_del_student SELECT (OLD).*;
    END IF;
    RETURN NULL;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to public.student';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.student ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS student_trigger_update ON public.student;
CREATE TRIGGER student_trigger_update
    AFTER INSERT OR UPDATE OR DELETE ON
    public.student FOR EACH ROW EXECUTE PROCEDURE public.student_update();

CREATE OR REPLACE FUNCTION public.student_detect_update_on_dejima_1_2()
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
IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'dejima_1_2_delta_action_flag') THEN
    insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT __dummy__.COL0 AS ID,__dummy__.COL1 AS UNIVERSITY,__dummy__.COL2 AS FIRST_NAME,__dummy__.COL3 AS LAST_NAME 
FROM (SELECT ∂_ins_dejima_1_2_a4_0.COL0 AS COL0, ∂_ins_dejima_1_2_a4_0.COL1 AS COL1, ∂_ins_dejima_1_2_a4_0.COL2 AS COL2, ∂_ins_dejima_1_2_a4_0.COL3 AS COL3 
FROM (SELECT p_0_a4_0.COL0 AS COL0, p_0_a4_0.COL1 AS COL1, p_0_a4_0.COL2 AS COL2, p_0_a4_0.COL3 AS COL3 
FROM (SELECT __temp__Δ_ins_student_a4_0.ID AS COL0, __temp__Δ_ins_student_a4_0.UNIVERSITY AS COL1, __temp__Δ_ins_student_a4_0.FIRST_NAME AS COL2, __temp__Δ_ins_student_a4_0.LAST_NAME AS COL3 
FROM __temp__Δ_ins_student AS __temp__Δ_ins_student_a4_0 
WHERE __temp__Δ_ins_student_a4_0.UNIVERSITY  <>  'Univ3' ) AS p_0_a4_0  ) AS ∂_ins_dejima_1_2_a4_0  ) AS __dummy__) as t);
    IF insertion_data IS NOT DISTINCT FROM NULL THEN 
        insertion_data := '[]';
    END IF; 
    deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT __dummy__.COL0 AS ID,__dummy__.COL1 AS UNIVERSITY,__dummy__.COL2 AS FIRST_NAME,__dummy__.COL3 AS LAST_NAME 
FROM (SELECT ∂_del_dejima_1_2_a4_0.COL0 AS COL0, ∂_del_dejima_1_2_a4_0.COL1 AS COL1, ∂_del_dejima_1_2_a4_0.COL2 AS COL2, ∂_del_dejima_1_2_a4_0.COL3 AS COL3 
FROM (SELECT p_0_a4_0.COL0 AS COL0, p_0_a4_0.COL1 AS COL1, p_0_a4_0.COL2 AS COL2, p_0_a4_0.COL3 AS COL3 
FROM (SELECT __temp__Δ_del_student_a4_0.ID AS COL0, __temp__Δ_del_student_a4_0.UNIVERSITY AS COL1, __temp__Δ_del_student_a4_0.FIRST_NAME AS COL2, __temp__Δ_del_student_a4_0.LAST_NAME AS COL3 
FROM __temp__Δ_del_student AS __temp__Δ_del_student_a4_0 
WHERE __temp__Δ_del_student_a4_0.UNIVERSITY  <>  'Univ3' ) AS p_0_a4_0  ) AS ∂_del_dejima_1_2_a4_0  ) AS __dummy__) as t);
    IF deletion_data IS NOT DISTINCT FROM NULL THEN 
        deletion_data := '[]';
    END IF; 
    IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
        user_name := (SELECT session_user);
        IF NOT (user_name = 'dejima') THEN 
            json_data := concat('{"view": ' , '"public.dejima_1_2"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
            result := public.dejima_1_2_run_shell(json_data);
            IF result = 'true' THEN 
                DROP TABLE __temp__Δ_ins_student;
                DROP TABLE __temp__Δ_del_student;
                DROP TABLE __temp__student;
            ELSE
                -- RAISE LOG 'result from running the sh script: %', result;
                RAISE check_violation USING MESSAGE = 'update on view is rejected by the external tool, result from running the sh script: ' 
                || result;
            END IF;
        ELSE 
            RAISE LOG 'function of detecting dejima update is called by % , no request sent to dejima proxy', user_name;

            -- update the table that stores the insertions and deletions we calculated
            DELETE FROM public.__dummy__dejima_1_2_detected_deletions;
            INSERT INTO public.__dummy__dejima_1_2_detected_deletions
                SELECT __dummy__.COL0 AS ID,__dummy__.COL1 AS UNIVERSITY,__dummy__.COL2 AS FIRST_NAME,__dummy__.COL3 AS LAST_NAME 
FROM (SELECT ∂_del_dejima_1_2_a4_0.COL0 AS COL0, ∂_del_dejima_1_2_a4_0.COL1 AS COL1, ∂_del_dejima_1_2_a4_0.COL2 AS COL2, ∂_del_dejima_1_2_a4_0.COL3 AS COL3 
FROM (SELECT p_0_a4_0.COL0 AS COL0, p_0_a4_0.COL1 AS COL1, p_0_a4_0.COL2 AS COL2, p_0_a4_0.COL3 AS COL3 
FROM (SELECT __temp__Δ_del_student_a4_0.ID AS COL0, __temp__Δ_del_student_a4_0.UNIVERSITY AS COL1, __temp__Δ_del_student_a4_0.FIRST_NAME AS COL2, __temp__Δ_del_student_a4_0.LAST_NAME AS COL3 
FROM __temp__Δ_del_student AS __temp__Δ_del_student_a4_0 
WHERE __temp__Δ_del_student_a4_0.UNIVERSITY  <>  'Univ3' ) AS p_0_a4_0  ) AS ∂_del_dejima_1_2_a4_0  ) AS __dummy__;

            DELETE FROM public.__dummy__dejima_1_2_detected_insertions;
            INSERT INTO public.__dummy__dejima_1_2_detected_insertions
                SELECT __dummy__.COL0 AS ID,__dummy__.COL1 AS UNIVERSITY,__dummy__.COL2 AS FIRST_NAME,__dummy__.COL3 AS LAST_NAME 
FROM (SELECT ∂_ins_dejima_1_2_a4_0.COL0 AS COL0, ∂_ins_dejima_1_2_a4_0.COL1 AS COL1, ∂_ins_dejima_1_2_a4_0.COL2 AS COL2, ∂_ins_dejima_1_2_a4_0.COL3 AS COL3 
FROM (SELECT p_0_a4_0.COL0 AS COL0, p_0_a4_0.COL1 AS COL1, p_0_a4_0.COL2 AS COL2, p_0_a4_0.COL3 AS COL3 
FROM (SELECT __temp__Δ_ins_student_a4_0.ID AS COL0, __temp__Δ_ins_student_a4_0.UNIVERSITY AS COL1, __temp__Δ_ins_student_a4_0.FIRST_NAME AS COL2, __temp__Δ_ins_student_a4_0.LAST_NAME AS COL3 
FROM __temp__Δ_ins_student AS __temp__Δ_ins_student_a4_0 
WHERE __temp__Δ_ins_student_a4_0.UNIVERSITY  <>  'Univ3' ) AS p_0_a4_0  ) AS ∂_ins_dejima_1_2_a4_0  ) AS __dummy__;
        END IF;
    END IF;
END IF;
RETURN NULL;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to public.student';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the function public.student_detect_update_on_dejima_1_2() ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS student_detect_update_on_dejima_1_2 ON public.student;
CREATE TRIGGER student_detect_update_on_dejima_1_2
    AFTER INSERT OR UPDATE OR DELETE ON
    public.student FOR EACH STATEMENT EXECUTE PROCEDURE public.student_detect_update_on_dejima_1_2();



CREATE OR REPLACE FUNCTION public.dejima_1_2_delta_action()
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
  temprecΔ_del_student public.student%ROWTYPE;
temprecΔ_ins_student public.student%ROWTYPE;
  BEGIN
    -- IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'dejima_1_2_delta_action_flag') THEN
        -- RAISE LOG 'execute procedure dejima_1_2_delta_action';
        CREATE TEMPORARY TABLE IF NOT EXISTS dejima_1_2_delta_action_flag ON COMMIT DROP AS (SELECT true as finish);
        IF EXISTS (SELECT WHERE false )
        THEN 
          RAISE check_violation USING MESSAGE = 'Invalid view update: constraints on the view are violated';
        END IF;
        IF EXISTS (SELECT WHERE false )
        THEN 
          RAISE check_violation USING MESSAGE = 'Invalid view update: constraints on the source relations are violated';
        END IF;
        CREATE TEMPORARY TABLE Δ_del_student WITH OIDS ON COMMIT DROP AS SELECT (ROW(COL0,COL1,COL2,COL3) :: public.student).* 
            FROM (SELECT Δ_del_student_a4_0.COL0 AS COL0, Δ_del_student_a4_0.COL1 AS COL1, Δ_del_student_a4_0.COL2 AS COL2, Δ_del_student_a4_0.COL3 AS COL3 
FROM (SELECT student_a4_0.ID AS COL0, student_a4_0.UNIVERSITY AS COL1, student_a4_0.FIRST_NAME AS COL2, student_a4_0.LAST_NAME AS COL3 
FROM public.student AS student_a4_0 
WHERE student_a4_0.UNIVERSITY  <>  'Univ3' AND NOT EXISTS ( SELECT * 
FROM (SELECT dejima_1_2_a4_0.ID AS COL0, dejima_1_2_a4_0.UNIVERSITY AS COL1, dejima_1_2_a4_0.FIRST_NAME AS COL2, dejima_1_2_a4_0.LAST_NAME AS COL3 
FROM public.dejima_1_2 AS dejima_1_2_a4_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_dejima_1_2 AS __temp__Δ_del_dejima_1_2_a4 
WHERE __temp__Δ_del_dejima_1_2_a4.LAST_NAME = dejima_1_2_a4_0.LAST_NAME AND __temp__Δ_del_dejima_1_2_a4.FIRST_NAME = dejima_1_2_a4_0.FIRST_NAME AND __temp__Δ_del_dejima_1_2_a4.UNIVERSITY = dejima_1_2_a4_0.UNIVERSITY AND __temp__Δ_del_dejima_1_2_a4.ID = dejima_1_2_a4_0.ID )  UNION SELECT __temp__Δ_ins_dejima_1_2_a4_0.ID AS COL0, __temp__Δ_ins_dejima_1_2_a4_0.UNIVERSITY AS COL1, __temp__Δ_ins_dejima_1_2_a4_0.FIRST_NAME AS COL2, __temp__Δ_ins_dejima_1_2_a4_0.LAST_NAME AS COL3 
FROM __temp__Δ_ins_dejima_1_2 AS __temp__Δ_ins_dejima_1_2_a4_0  ) AS new_dejima_1_2_a4 
WHERE new_dejima_1_2_a4.COL3 = student_a4_0.LAST_NAME AND new_dejima_1_2_a4.COL2 = student_a4_0.FIRST_NAME AND new_dejima_1_2_a4.COL1 = student_a4_0.UNIVERSITY AND new_dejima_1_2_a4.COL0 = student_a4_0.ID ) ) AS Δ_del_student_a4_0  ) AS Δ_del_student_extra_alias;

CREATE TEMPORARY TABLE Δ_ins_student WITH OIDS ON COMMIT DROP AS SELECT (ROW(COL0,COL1,COL2,COL3) :: public.student).* 
            FROM (SELECT Δ_ins_student_a4_0.COL0 AS COL0, Δ_ins_student_a4_0.COL1 AS COL1, Δ_ins_student_a4_0.COL2 AS COL2, Δ_ins_student_a4_0.COL3 AS COL3 
FROM (SELECT new_dejima_1_2_a4_0.COL0 AS COL0, new_dejima_1_2_a4_0.COL1 AS COL1, new_dejima_1_2_a4_0.COL2 AS COL2, new_dejima_1_2_a4_0.COL3 AS COL3 
FROM (SELECT dejima_1_2_a4_0.ID AS COL0, dejima_1_2_a4_0.UNIVERSITY AS COL1, dejima_1_2_a4_0.FIRST_NAME AS COL2, dejima_1_2_a4_0.LAST_NAME AS COL3 
FROM public.dejima_1_2 AS dejima_1_2_a4_0 
WHERE NOT EXISTS ( SELECT * 
FROM __temp__Δ_del_dejima_1_2 AS __temp__Δ_del_dejima_1_2_a4 
WHERE __temp__Δ_del_dejima_1_2_a4.LAST_NAME = dejima_1_2_a4_0.LAST_NAME AND __temp__Δ_del_dejima_1_2_a4.FIRST_NAME = dejima_1_2_a4_0.FIRST_NAME AND __temp__Δ_del_dejima_1_2_a4.UNIVERSITY = dejima_1_2_a4_0.UNIVERSITY AND __temp__Δ_del_dejima_1_2_a4.ID = dejima_1_2_a4_0.ID )  UNION SELECT __temp__Δ_ins_dejima_1_2_a4_0.ID AS COL0, __temp__Δ_ins_dejima_1_2_a4_0.UNIVERSITY AS COL1, __temp__Δ_ins_dejima_1_2_a4_0.FIRST_NAME AS COL2, __temp__Δ_ins_dejima_1_2_a4_0.LAST_NAME AS COL3 
FROM __temp__Δ_ins_dejima_1_2 AS __temp__Δ_ins_dejima_1_2_a4_0  ) AS new_dejima_1_2_a4_0 
WHERE NOT EXISTS ( SELECT * 
FROM public.student AS student_a4 
WHERE student_a4.LAST_NAME = new_dejima_1_2_a4_0.COL3 AND student_a4.FIRST_NAME = new_dejima_1_2_a4_0.COL2 AND student_a4.UNIVERSITY = new_dejima_1_2_a4_0.COL1 AND student_a4.ID = new_dejima_1_2_a4_0.COL0 ) ) AS Δ_ins_student_a4_0  ) AS Δ_ins_student_extra_alia 
            EXCEPT 
            SELECT * FROM  public.student; 

FOR temprecΔ_del_student IN ( SELECT * FROM Δ_del_student) LOOP 
            DELETE FROM public.student WHERE ROW(ID,UNIVERSITY,FIRST_NAME,LAST_NAME) =  temprecΔ_del_student;
            END LOOP;
DROP TABLE Δ_del_student;

INSERT INTO public.student (SELECT * FROM  Δ_ins_student) ; 
DROP TABLE Δ_ins_student;
        
        insertion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM __temp__Δ_ins_dejima_1_2) as t);
        IF insertion_data IS NOT DISTINCT FROM NULL THEN 
            insertion_data := '[]';
        END IF; 
        deletion_data := (SELECT (array_to_json(array_agg(t)))::text FROM (SELECT * FROM __temp__Δ_del_dejima_1_2) as t);
        IF deletion_data IS NOT DISTINCT FROM NULL THEN 
            deletion_data := '[]';
        END IF; 
        IF (insertion_data IS DISTINCT FROM '[]') OR (deletion_data IS DISTINCT FROM '[]') THEN 
            user_name := (SELECT session_user);
            IF NOT (user_name = 'dejima') THEN 
                json_data := concat('{"view": ' , '"public.dejima_1_2"', ', ' , '"insertions": ' , insertion_data , ', ' , '"deletions": ' , deletion_data , '}');
                result := public.dejima_1_2_run_shell(json_data);
                IF NOT (result = 'true') THEN
                    -- RAISE LOG 'result from running the sh script: %', result;
                    RAISE check_violation USING MESSAGE = 'update on view is rejected by the external tool, result from running the sh script: ' 
                    || result;
                END IF;
            ELSE 
                RAISE LOG 'function of detecting dejima update is called by % , no request sent to dejima proxy', user_name;

                -- update the table that stores the insertions and deletions we calculated
                DELETE FROM public.__dummy__dejima_1_2_detected_deletions;
                INSERT INTO public.__dummy__dejima_1_2_detected_deletions
                    SELECT * FROM __temp__Δ_del_dejima_1_2;

                DELETE FROM public.__dummy__dejima_1_2_detected_insertions;
                INSERT INTO public.__dummy__dejima_1_2_detected_insertions
                    SELECT * FROM __temp__Δ_ins_dejima_1_2;
            END IF;
        END IF;
    -- END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.dejima_1_2';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.dejima_1_2 ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

CREATE OR REPLACE FUNCTION public.dejima_1_2_materialization()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
  BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = '__temp__Δ_ins_dejima_1_2' OR table_name = '__temp__Δ_del_dejima_1_2')
    THEN
        -- RAISE LOG 'execute procedure dejima_1_2_materialization';
        CREATE TEMPORARY TABLE __temp__Δ_ins_dejima_1_2 ( LIKE public.dejima_1_2 INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE CONSTRAINT TRIGGER __temp__dejima_1_2_trigger_delta_action
        AFTER INSERT OR UPDATE OR DELETE ON 
            __temp__Δ_ins_dejima_1_2 DEFERRABLE INITIALLY DEFERRED 
            FOR EACH ROW EXECUTE PROCEDURE public.dejima_1_2_delta_action();

        CREATE TEMPORARY TABLE __temp__Δ_del_dejima_1_2 ( LIKE public.dejima_1_2 INCLUDING ALL ) WITH OIDS ON COMMIT DROP;
        CREATE CONSTRAINT TRIGGER __temp__dejima_1_2_trigger_delta_action
        AFTER INSERT OR UPDATE OR DELETE ON 
            __temp__Δ_del_dejima_1_2 DEFERRABLE INITIALLY DEFERRED 
            FOR EACH ROW EXECUTE PROCEDURE public.dejima_1_2_delta_action();
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.dejima_1_2';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.dejima_1_2 ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS dejima_1_2_trigger_materialization ON public.dejima_1_2;
CREATE TRIGGER dejima_1_2_trigger_materialization
    BEFORE INSERT OR UPDATE OR DELETE ON
      public.dejima_1_2 FOR EACH STATEMENT EXECUTE PROCEDURE public.dejima_1_2_materialization();

CREATE OR REPLACE FUNCTION public.dejima_1_2_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
  BEGIN
    -- RAISE LOG 'execute procedure dejima_1_2_update';
    IF TG_OP = 'INSERT' THEN
      -- RAISE LOG 'NEW: %', NEW;
      IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update on view: view does not accept null value';
      END IF;
      DELETE FROM __temp__Δ_del_dejima_1_2 WHERE ROW(ID,UNIVERSITY,FIRST_NAME,LAST_NAME) = NEW;
      INSERT INTO __temp__Δ_ins_dejima_1_2 SELECT (NEW).*; 
    ELSIF TG_OP = 'UPDATE' THEN
      IF (SELECT count(*) FILTER (WHERE j.value = jsonb 'null') FROM  jsonb_each(to_jsonb(NEW)) j) > 0 THEN 
        RAISE check_violation USING MESSAGE = 'Invalid update on view: view does not accept null value';
      END IF;
      DELETE FROM __temp__Δ_ins_dejima_1_2 WHERE ROW(ID,UNIVERSITY,FIRST_NAME,LAST_NAME) = OLD;
      INSERT INTO __temp__Δ_del_dejima_1_2 SELECT (OLD).*;
      DELETE FROM __temp__Δ_del_dejima_1_2 WHERE ROW(ID,UNIVERSITY,FIRST_NAME,LAST_NAME) = NEW;
      INSERT INTO __temp__Δ_ins_dejima_1_2 SELECT (NEW).*; 
    ELSIF TG_OP = 'DELETE' THEN
      -- RAISE LOG 'OLD: %', OLD;
      DELETE FROM __temp__Δ_ins_dejima_1_2 WHERE ROW(ID,UNIVERSITY,FIRST_NAME,LAST_NAME) = OLD;
      INSERT INTO __temp__Δ_del_dejima_1_2 SELECT (OLD).*;
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE object_not_in_prerequisite_state USING MESSAGE = 'no permission to insert or delete or update to source relations of public.dejima_1_2';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS text_var1 = RETURNED_SQLSTATE,
                                text_var2 = PG_EXCEPTION_DETAIL,
                                text_var3 = MESSAGE_TEXT;
        RAISE SQLSTATE 'DA000' USING MESSAGE = 'error on the trigger of public.dejima_1_2 ; error code: ' || text_var1 || ' ; ' || text_var2 ||' ; ' || text_var3;
        RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS dejima_1_2_trigger_update ON public.dejima_1_2;
CREATE TRIGGER dejima_1_2_trigger_update
    INSTEAD OF INSERT OR UPDATE OR DELETE ON
      public.dejima_1_2 FOR EACH ROW EXECUTE PROCEDURE public.dejima_1_2_update();

