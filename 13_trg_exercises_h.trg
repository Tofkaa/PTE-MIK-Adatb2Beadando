CREATE OR REPLACE TRIGGER trg_exercises_h
  AFTER INSERT OR UPDATE OR DELETE ON exercises
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
    v_current_id := :new.exercise_id;
  ELSIF updating
  THEN
    v_action     := 'U';
    v_current_id := :new.exercise_id;
  ELSIF deleting
  THEN
    v_action     := 'D';
    v_current_id := :old.exercise_id;
  END IF;

  SELECT nvl(MAX(version_no), 0) + 1
    INTO v_next_ver
    FROM exercises_h
   WHERE exercise_id = v_current_id;

  IF inserting
     OR updating
  THEN
    INSERT INTO exercises_h
      (exercise_id
      ,lesson_id
      ,TYPE
      ,content
      ,correct_answer
      ,audio_url
      ,image_url
      ,hist_id
      ,hist_action
      ,hist_user
      ,hist_date
      ,version_no)
    VALUES
      (:new.exercise_id
      ,:new.lesson_id
      ,:new.type
      ,:new.content
      ,:new.correct_answer
      ,:new.audio_url
      ,:new.image_url
      ,seq_exercises_h.nextval
      ,v_action
      ,v_os_user
      ,systimestamp
      ,v_next_ver);
  ELSIF deleting
  THEN
    INSERT INTO exercises_h
      (exercise_id
      ,lesson_id
      ,TYPE
      ,content
      ,correct_answer
      ,audio_url
      ,image_url
      ,hist_id
      ,hist_action
      ,hist_user
      ,hist_date
      ,version_no)
    VALUES
      (:old.exercise_id
      ,:old.lesson_id
      ,:old.type
      ,:old.content
      ,:old.correct_answer
      ,:old.audio_url
      ,:old.image_url
      ,seq_exercises_h.nextval
      ,v_action
      ,v_os_user
      ,systimestamp
      ,v_next_ver);
  END IF;
END;
/
