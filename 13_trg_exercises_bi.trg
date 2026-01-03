CREATE OR REPLACE TRIGGER trg_exercises_bi
  BEFORE INSERT ON exercises
  FOR EACH ROW
BEGIN
  IF :new.exercise_id IS NULL
  THEN
    :new.exercise_id := seq_exercises.nextval;
  END IF;
END;
/
