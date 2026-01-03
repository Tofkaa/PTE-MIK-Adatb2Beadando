CREATE OR REPLACE TRIGGER trg_classroom_members_bi
  BEFORE INSERT ON classroom_members
  FOR EACH ROW
BEGIN
  IF :new.classroom_member_id IS NULL
  THEN
    :new.classroom_member_id := seq_classroom_members.nextval;
  END IF;
END;
/
