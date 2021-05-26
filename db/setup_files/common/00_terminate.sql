CREATE EXTENSION IF NOT EXISTS plsh;

CREATE OR REPLACE FUNCTION public.terminate_run_shell(text) RETURNS text AS $$
#!/bin/sh

result=$(curl -s -X POST -H "Content-Type: application/json" -H "Connection: close" $DEJIMA_TERMINATION_ENDPOINT -d "$1")
$$ LANGUAGE plsh;

CREATE OR REPLACE FUNCTION public.get_peername_from_env() RETURNS text AS $$
#!/bin/sh
echo $PEER_NAME
$$ LANGUAGE plsh;

CREATE OR REPLACE FUNCTION public.terminate()
RETURNS trigger
LANGUAGE plpgsql
AS $$
  DECLARE
  json_data text;
  result text;
  xid text;
  user_name text;
  peer_name text;
  BEGIN
  user_name := (SELECT session_user);
  IF NOT (user_name = 'dejima') THEN 
    IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'termination_flag') THEN
        -- RAISE LOG 'execute procedure dejima_b_c_delta_action';
        CREATE TEMPORARY TABLE termination_flag ON COMMIT DROP AS (SELECT true as finish);

        xid := (SELECT txid_current());
        peer_name := public.get_peername_from_env();

        IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'dejima_abort_flag') THEN
          json_data := concat('{"xid": "', peer_name, '_', xid, '", "result": "commit"}');
          result := public.terminate_run_shell(json_data);
        ELSE
          json_data := concat('{"xid": "', peer_name, '_', xid, '", "result": "abort"}');
          result := public.terminate_run_shell(json_data);
          RAISE USING MESSAGE = 'abort following 2PC';
        END IF;
    END IF;
  END IF;
  RETURN NULL;
  END;
$$;