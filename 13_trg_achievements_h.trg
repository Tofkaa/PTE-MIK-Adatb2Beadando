CREATE OR REPLACE TRIGGER trg_achievements_h
  AFTER INSERT OR UPDATE OR DELETE ON achievements
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
    v_current_id := :new.achievement_id;
  ELSIF updating
  THEN
    v_action     := 'U';
    v_current_id := :new.achievement_id;
  ELSIF deleting
  THEN
    v_action     := 'D';
    v_current_id := :old.achievement_id;
  END IF;

  SELECT nvl(MAX(version_no), 0) + 1
    INTO v_next_ver
    FROM achievements_h
   WHERE achievement_id = v_current_id;

  IF inserting
     OR updating
  THEN
    INSERT INTO achievements_h
      (achievement_id
      ,NAME
      ,description
      ,criteria
      ,icon_url
      ,hist_id
      ,hist_action
      ,hist_user
      ,hist_date
      ,version_no)
    VALUES
      (:new.achievement_id
      ,:new.name
      ,:new.description
      ,:new.criteria
      ,:new.icon_url
      ,seq_achievements_h.nextval
      ,v_action
      ,v_os_user
      ,systimestamp
      ,v_next_ver);
  ELSIF deleting
  THEN
    INSERT INTO achievements_h
      (achievement_id
      ,NAME
      ,description
      ,criteria
      ,icon_url
      ,hist_id
      ,hist_action
      ,hist_user
      ,hist_date
      ,version_no)
    VALUES
      (:old.achievement_id
      ,:old.name
      ,:old.description
      ,:old.criteria
      ,:old.icon_url
      ,seq_achievements_h.nextval
      ,v_action
      ,v_os_user
      ,systimestamp
      ,v_next_ver);
  END IF;
END;
/
