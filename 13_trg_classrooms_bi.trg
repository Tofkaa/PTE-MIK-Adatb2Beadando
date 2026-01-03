CREATE OR REPLACE TRIGGER trg_classrooms_bi
  BEFORE INSERT ON classrooms
  FOR EACH ROW
BEGIN
  IF :new.classroom_id IS NULL
  THEN
    :new.classroom_id := seq_classrooms.nextval;
  END IF;
END;
/
