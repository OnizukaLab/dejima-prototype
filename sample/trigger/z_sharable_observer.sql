CREATE OR REPLACE FUNCTION public.sharable_observer()
RETURNS trigger
LANGUAGE plpgsql
AS $$
  BEGIN
  IF (OLD.sharable != NEW.sharable) THEN
    -- do something
    RAISE LOG 'A change of "sharable" column detected';
  END IF;
  RETURN NEW;
  END;
$$;

CREATE TRIGGER z_sharable_observer
    AFTER UPDATE
    ON public.bt
    FOR EACH ROW EXECUTE PROCEDURE public.sharable_observer();