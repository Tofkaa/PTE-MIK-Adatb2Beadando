CREATE OR REPLACE TRIGGER trg_lesson_topics_bi
  BEFORE INSERT ON lesson_topics
  FOR EACH ROW
BEGIN
  IF :new.topic_id IS NULL
  THEN
    :new.topic_id := seq_lesson_topics.nextval;
  END IF;
END;
/
