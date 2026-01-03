CREATE OR REPLACE TRIGGER trg_lessons_bi
  BEFORE INSERT ON lessons
  FOR EACH ROW
BEGIN
  IF :new.lesson_id IS NULL
  THEN
    :new.lesson_id := seq_lessons.nextval;
  END IF;
END;
/
