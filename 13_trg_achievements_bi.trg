CREATE OR REPLACE TRIGGER trg_achievements_bi
  BEFORE INSERT ON achievements
  FOR EACH ROW
BEGIN
  IF :new.achievement_id IS NULL
  THEN
    :new.achievement_id := seq_achievements.nextval;
  END IF;
END;
/
