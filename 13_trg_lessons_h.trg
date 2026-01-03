CREATE OR REPLACE TRIGGER trg_lessons_h
  AFTER INSERT OR UPDATE OR DELETE ON lessons
  FOR EACH ROW
DECLARE
  v_action     CHAR(1);
  v_os_user    VARCHAR2(50) := sys_context('USERENV', 'OS_USER');
  v_next_ver   NUMBER;
  v_current_id NUMBER;
BEGIN
  IF inserting
  THEN
    v_action     := 'I';
    v_current_id := :new.lesson_id;
  ELSIF updating
  THEN
    v_action     := 'U';
    v_current_id := :new.lesson_id;
  ELSIF deleting
  THEN
    v_action     := 'D';
    v_current_id := :old.lesson_id;
  END IF;

  SELECT nvl(MAX(version_no), 0) + 1
    INTO v_next_ver
    FROM lessons_h
   WHERE lesson_id = v_current_id;

  IF inserting
     OR updating
  THEN
    INSERT INTO lessons_h
      (lesson_id
      ,topic_id
      ,title
      ,difficulty
      ,LANGUAGE
      ,description
      ,hist_id
      ,hist_action
      ,hist_user
      ,hist_date
      ,version_no)
    VALUES
      (:new.lesson_id
      ,:new.topic_id
      ,:new.title
      ,:new.difficulty
      ,:new.language
      ,:new.description
      ,seq_lessons_h.nextval
      ,v_action
      ,v_os_user
      ,systimestamp
      ,v_next_ver);
  ELSIF deleting
  THEN
    INSERT INTO lessons_h
      (lesson_id
      ,topic_id
      ,title
      ,difficulty
      ,LANGUAGE
      ,description
      ,hist_id
      ,hist_action
      ,hist_user
      ,hist_date
      ,version_no)
    VALUES
      (:old.lesson_id
      ,:old.topic_id
      ,:old.title
      ,:old.difficulty
      ,:old.language
      ,:old.description
      ,seq_lessons_h.nextval
      ,v_action
      ,v_os_user
      ,systimestamp
      ,v_next_ver);
  END IF;
END;
/
