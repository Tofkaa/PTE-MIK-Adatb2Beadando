CREATE OR REPLACE TRIGGER trg_users_h
  AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW
DECLARE
  v_action     CHAR(1);
  v_os_user    VARCHAR2(50) := sys_context('USERENV', 'OS_USER');
  v_next_ver   NUMBER;
  v_current_id RAW(16);
BEGIN

  IF inserting THEN
    v_action     := 'I';
    v_current_id := :new.user_id;
  ELSIF updating THEN
    v_action     := 'U';
    v_current_id := :new.user_id;
  ELSIF deleting THEN
    v_action     := 'D';
    v_current_id := :old.user_id;
  END IF;

  SELECT nvl(MAX(version_no), 0) + 1
    INTO v_next_ver
    FROM users_h
   WHERE user_id = v_current_id;

  IF inserting OR updating THEN
    INSERT INTO users_h
      (user_id
      ,NAME
      ,email
      ,password_hash
      ,role
      ,xp
      ,streak
      ,created_at
      ,last_login
      ,profile_picture_url
      ,preferred_language
      ,hist_id
      ,hist_action
      ,hist_user
      ,hist_date
      ,version_no)
    VALUES
      (:new.user_id
      ,:new.name
      ,:new.email
      ,:new.password_hash
      ,:new.role
      ,:new.xp
      ,:new.streak
      ,:new.created_at
      ,:new.last_login
      ,:new.profile_picture_url
      ,:new.preferred_language
      ,seq_users_h.nextval
      ,v_action
      ,v_os_user
      ,systimestamp
      ,v_next_ver);
   
  ELSIF deleting THEN
    INSERT INTO users_h
      (user_id
      ,NAME
      ,email
      ,password_hash
      ,role
      ,xp
      ,streak
      ,created_at
      ,last_login
      ,profile_picture_url
      ,preferred_language
      ,hist_id
      ,hist_action
      ,hist_user
      ,hist_date
      ,version_no)
    VALUES
      (:old.user_id
      ,:old.name
      ,:old.email
      ,:old.password_hash
      ,:old.role
      ,:old.xp
      ,:old.streak
      ,:old.created_at
      ,:old.last_login
      ,:old.profile_picture_url
      ,:old.preferred_language
      ,seq_users_h.nextval
      ,v_action
      ,v_os_user
      ,systimestamp
      ,v_next_ver);
  END IF;
END;
/
