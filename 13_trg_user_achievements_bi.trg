CREATE OR REPLACE TRIGGER trg_user_achievements_bi
  BEFORE INSERT ON user_achievements
  FOR EACH ROW
BEGIN
  IF :new.user_achievement_id IS NULL
  THEN
    :new.user_achievement_id := seq_user_achievements.nextval;
  END IF;
END;
/
