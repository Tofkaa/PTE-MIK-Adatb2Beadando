CREATE OR REPLACE TRIGGER trg_classrooms_h
  AFTER INSERT OR UPDATE OR DELETE ON classrooms
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
    v_current_id := :new.classroom_id;
  ELSIF updating
  THEN
    v_action     := 'U';
    v_current_id := :new.classroom_id;
  ELSIF deleting
  THEN
    v_action     := 'D';
    v_current_id := :old.classroom_id;
  END IF;

  SELECT nvl(MAX(version_no), 0) + 1
    INTO v_next_ver
    FROM classrooms_h
   WHERE classroom_id = v_current_id;

  IF inserting
     OR updating
  THEN
    INSERT INTO classrooms_h
      (classroom_id
      ,NAME
      ,description
      ,teacher_id
      ,invite_code
      ,created_at
      ,hist_id
      ,hist_action
      ,hist_user
      ,hist_date
      ,version_no)
    VALUES
      (:new.classroom_id
      ,:new.name
      ,:new.description
      ,:new.teacher_id
      ,:new.invite_code
      ,:new.created_at
      ,seq_classrooms_h.nextval
      ,v_action
      ,v_os_user
      ,systimestamp
      ,v_next_ver);
  ELSIF deleting
  THEN
    INSERT INTO classrooms_h
      (classroom_id
      ,NAME
      ,description
      ,teacher_id
      ,invite_code
      ,created_at
      ,hist_id
      ,hist_action
      ,hist_user
      ,hist_date
      ,version_no)
    VALUES
      (:old.classroom_id
      ,:old.name
      ,:old.description
      ,:old.teacher_id
      ,:old.invite_code
      ,:old.created_at
      ,seq_classrooms_h.nextval
      ,v_action
      ,v_os_user
      ,systimestamp
      ,v_next_ver);
  END IF;
END;
/
