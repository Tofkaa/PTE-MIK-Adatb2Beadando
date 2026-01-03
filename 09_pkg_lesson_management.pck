-- ======================================================
-- lesson management package
-- ======================================================
CREATE OR REPLACE PACKAGE pkg_lesson_management AS
  ---------------------------------------------------------------------
  -- LESSON TOPICS
  ---------------------------------------------------------------------

  PROCEDURE create_lesson_topic(p_name        IN VARCHAR2
                               ,p_description IN VARCHAR2);
  PROCEDURE update_lesson_topic(p_topic_id    IN NUMBER
                               ,p_name        IN VARCHAR2
                               ,p_description IN VARCHAR2);
  PROCEDURE delete_lesson_topic(p_topic_id IN NUMBER);
  FUNCTION get_all_topics RETURN SYS_REFCURSOR;
  FUNCTION get_topic_by_id(p_topic_id IN NUMBER) RETURN SYS_REFCURSOR;

  ---------------------------------------------------------------------
  -- LESSONS
  ---------------------------------------------------------------------
  PROCEDURE create_lesson(p_title       IN VARCHAR2
                         ,p_difficulty  IN VARCHAR2
                         ,p_language    IN VARCHAR2
                         ,p_description IN VARCHAR2
                         ,p_topic_id    IN NUMBER DEFAULT NULL);
  PROCEDURE update_lesson(p_lesson_id   IN NUMBER
                         ,p_title       IN VARCHAR2
                         ,p_difficulty  IN VARCHAR2
                         ,p_language    IN VARCHAR2
                         ,p_description IN VARCHAR2
                         ,p_topic_id    IN NUMBER DEFAULT NULL);
  PROCEDURE delete_lesson(p_lesson_id IN NUMBER);
  FUNCTION get_lessons_by_topic(p_topic_id IN NUMBER) RETURN SYS_REFCURSOR;
  FUNCTION get_lesson_by_id(p_lesson_id IN NUMBER) RETURN SYS_REFCURSOR;
  FUNCTION get_lesson_statistics(p_lesson_id IN NUMBER)
    RETURN ty_lesson_performance;
  FUNCTION get_all_lesson_statistics RETURN ty_lesson_performance_tab
    PIPELINED;

  ---------------------------------------------------------------------
  -- EXERCISES
  ---------------------------------------------------------------------
  PROCEDURE create_exercise(p_lesson_id      IN NUMBER
                           ,p_type           IN VARCHAR2
                           ,p_content        IN VARCHAR2
                           ,p_correct_answer IN VARCHAR2
                           ,p_audio_url      IN VARCHAR2
                           ,p_image_url      IN VARCHAR2);
  PROCEDURE update_exercise(p_exercise_id    IN NUMBER
                           ,p_type           IN VARCHAR2
                           ,p_content        IN VARCHAR2
                           ,p_correct_answer IN VARCHAR2
                           ,p_audio_url      IN VARCHAR2
                           ,p_image_url      IN VARCHAR2);
  PROCEDURE delete_exercise(p_exercise_id IN NUMBER);
  FUNCTION get_exercises_by_lesson(p_lesson_id IN NUMBER)
    RETURN SYS_REFCURSOR;
  FUNCTION get_exercise_by_id(p_exercise_id IN NUMBER) RETURN SYS_REFCURSOR;

END pkg_lesson_management;
/
CREATE OR REPLACE PACKAGE BODY pkg_lesson_management AS

  ---------------------------------------------------------------------
  -- LESSON TOPICS
  ---------------------------------------------------------------------
  PROCEDURE create_lesson_topic(p_name        IN VARCHAR2
                               ,p_description IN VARCHAR2) AS
  BEGIN
    INSERT INTO lesson_topics
      (NAME
      ,description)
    VALUES
      (p_name
      ,p_description);
  
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'NAME: ' || p_name,
                                                'pkg_lesson_management.create_lesson_topic');
  END;

  PROCEDURE update_lesson_topic(p_topic_id    IN NUMBER
                               ,p_name        IN VARCHAR2
                               ,p_description IN VARCHAR2) AS
  BEGIN
    UPDATE lesson_topics
       SET NAME        = p_name
          ,description = p_description
     WHERE topic_id = p_topic_id;
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'Téma nem található',
                                                'ID: ' || p_topic_id,
                                                'pkg_lesson_management.update_lesson_topic');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_topic_id,
                                                'pkg_lesson_management.update_lesson_topic');
  END;

  PROCEDURE delete_lesson_topic(p_topic_id IN NUMBER) AS
  BEGIN
    DELETE FROM lesson_topics WHERE topic_id = p_topic_id;
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'Téma nem található',
                                                'ID: ' || p_topic_id,
                                                'pkg_lesson_management.delete_lesson_topic');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_topic_id,
                                                'pkg_lesson_management.delete_lesson_topic');
  END;

  FUNCTION get_all_topics RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT topic_id
            ,NAME
            ,description
        FROM lesson_topics
       ORDER BY NAME;
    RETURN v_cursor;
  END;

  FUNCTION get_topic_by_id(p_topic_id IN NUMBER) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT topic_id
            ,NAME
            ,description
        FROM lesson_topics
       WHERE topic_id = p_topic_id;
    RETURN v_cursor;
  END;

  ---------------------------------------------------------------------
  -- LESSONS
  ---------------------------------------------------------------------
  PROCEDURE create_lesson(p_title       IN VARCHAR2
                         ,p_difficulty  IN VARCHAR2
                         ,p_language    IN VARCHAR2
                         ,p_description IN VARCHAR2
                         ,p_topic_id    IN NUMBER DEFAULT NULL) AS
  BEGIN
    INSERT INTO lessons
      (title
      ,difficulty
      ,LANGUAGE
      ,description
      ,topic_id)
    VALUES
      (p_title
      ,p_difficulty
      ,p_language
      ,p_description
      ,p_topic_id);
  
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'Title: ' || p_title,
                                                'pkg_lesson_management.create_lesson');
  END create_lesson;

  PROCEDURE update_lesson(p_lesson_id   IN NUMBER
                         ,p_title       IN VARCHAR2
                         ,p_difficulty  IN VARCHAR2
                         ,p_language    IN VARCHAR2
                         ,p_description IN VARCHAR2
                         ,p_topic_id    IN NUMBER DEFAULT NULL) AS
  BEGIN
    UPDATE lessons
       SET title       = p_title
          ,difficulty  = p_difficulty
          ,LANGUAGE    = p_language
          ,description = p_description
          ,topic_id    = p_topic_id
     WHERE lesson_id = p_lesson_id;
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'Lecke nem található',
                                                'ID: ' || p_lesson_id,
                                                'pkg_lesson_management.update_lesson');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_lesson_id,
                                                'pkg_lesson_management.update_lesson');
  END;

  PROCEDURE delete_lesson(p_lesson_id IN NUMBER) AS
  BEGIN
    DELETE FROM lessons WHERE lesson_id = p_lesson_id;
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'Lecke nem található',
                                                'ID: ' || p_lesson_id,
                                                'pkg_lesson_management.delete_lesson');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_lesson_id,
                                                'pkg_lesson_management.delete_lesson');
  END;

  FUNCTION get_lessons_by_topic(p_topic_id IN NUMBER) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT lesson_id
            ,title
            ,difficulty
            ,LANGUAGE
            ,description
        FROM lessons
       WHERE topic_id = p_topic_id
       ORDER BY title;
    RETURN v_cursor;
  END;

  FUNCTION get_lesson_by_id(p_lesson_id IN NUMBER) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT lesson_id
            ,topic_id
            ,title
            ,difficulty
            ,LANGUAGE
            ,description
        FROM lessons
       WHERE lesson_id = p_lesson_id;
    RETURN v_cursor;
  END;

  FUNCTION get_lesson_statistics(p_lesson_id IN NUMBER)
    RETURN ty_lesson_performance AS
    v_result ty_lesson_performance;
  BEGIN
    SELECT ty_lesson_performance(l.lesson_id,
                                 l.title,
                                 nvl(AVG(r.score), 0),
                                 nvl(COUNT(r.result_id), 0),
                                 CASE
                                   WHEN COUNT(r.result_id) = 0 THEN
                                    0
                                   ELSE
                                    round(SUM(CASE
                                                WHEN p.is_completed = 'Y' THEN
                                                 1
                                                ELSE
                                                 0
                                              END) / COUNT(r.result_id) * 100,
                                          2)
                                 END)
      INTO v_result
      FROM lessons l
      LEFT JOIN results r
        ON r.lesson_id = l.lesson_id
      LEFT JOIN progress p
        ON p.lesson_id = l.lesson_id
     WHERE l.lesson_id = p_lesson_id
     GROUP BY l.lesson_id
             ,l.title;
  
    RETURN v_result;
  EXCEPTION
    WHEN no_data_found THEN
      RETURN ty_lesson_performance(p_lesson_id, NULL, 0, 0, 0);
  END get_lesson_statistics;

  FUNCTION get_all_lesson_statistics RETURN ty_lesson_performance_tab
    PIPELINED AS
  BEGIN
    FOR rec IN (SELECT l.lesson_id
                      ,l.title
                      ,nvl(AVG(r.score), 0) AS avg_score
                      ,COUNT(r.result_id) AS attempt_count
                      ,CASE
                         WHEN COUNT(r.result_id) = 0 THEN
                          0
                         ELSE
                          round((SUM(CASE
                                       WHEN p.is_completed = 'Y' THEN
                                        1
                                       ELSE
                                        0
                                     END) / COUNT(r.result_id)) * 100,
                                2)
                       END AS completion_rate
                  FROM lessons l
                  LEFT JOIN results r
                    ON r.lesson_id = l.lesson_id
                  LEFT JOIN progress p
                    ON p.lesson_id = l.lesson_id
                 GROUP BY l.lesson_id
                         ,l.title
                 ORDER BY l.lesson_id)
    LOOP
      PIPE ROW(ty_lesson_performance(rec.lesson_id,
                                     rec.title,
                                     rec.avg_score,
                                     rec.attempt_count,
                                     rec.completion_rate));
    END LOOP;
  
    RETURN;
  END get_all_lesson_statistics;

  ---------------------------------------------------------------------
  -- EXERCISES
  ---------------------------------------------------------------------
  PROCEDURE create_exercise(p_lesson_id      IN NUMBER
                           ,p_type           IN VARCHAR2
                           ,p_content        IN VARCHAR2
                           ,p_correct_answer IN VARCHAR2
                           ,p_audio_url      IN VARCHAR2
                           ,p_image_url      IN VARCHAR2) AS
  BEGIN
    INSERT INTO exercises
      (lesson_id
      ,TYPE
      ,content
      ,correct_answer
      ,audio_url
      ,image_url)
    VALUES
      (p_lesson_id
      ,p_type
      ,p_content
      ,p_correct_answer
      ,p_audio_url
      ,p_image_url);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_lesson_id,
                                                'pkg_lesson_management.create_exercise');
  END;

  PROCEDURE update_exercise(p_exercise_id    IN NUMBER
                           ,p_type           IN VARCHAR2
                           ,p_content        IN VARCHAR2
                           ,p_correct_answer IN VARCHAR2
                           ,p_audio_url      IN VARCHAR2
                           ,p_image_url      IN VARCHAR2) AS
  BEGIN
    UPDATE exercises
       SET TYPE           = p_type
          ,content        = p_content
          ,correct_answer = p_correct_answer
          ,audio_url      = p_audio_url
          ,image_url      = p_image_url
     WHERE exercise_id = p_exercise_id;
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'Feladat nem található',
                                                'ID: ' || p_exercise_id,
                                                'pkg_lesson_management.update_exercise');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_exercise_id,
                                                'pkg_lesson_management.update_exercise');
  END;

  PROCEDURE delete_exercise(p_exercise_id IN NUMBER) AS
  BEGIN
    DELETE FROM exercises WHERE exercise_id = p_exercise_id;
  
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'Feladat nem található',
                                                'ID: ' || p_exercise_id,
                                                'pkg_lesson_management.update_exercise');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_exercise_id,
                                                'pkg_lesson_management.update_exercise');
  END;

  FUNCTION get_exercises_by_lesson(p_lesson_id IN NUMBER)
    RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT exercise_id
            ,TYPE
            ,content
            ,correct_answer
            ,audio_url
            ,image_url
        FROM exercises
       WHERE lesson_id = p_lesson_id
       ORDER BY exercise_id;
    RETURN v_cursor;
  END;

  FUNCTION get_exercise_by_id(p_exercise_id IN NUMBER) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT exercise_id
            ,lesson_id
            ,TYPE
            ,content
            ,correct_answer
            ,audio_url
            ,image_url
        FROM exercises
       WHERE exercise_id = p_exercise_id;
    RETURN v_cursor;
  END;

END pkg_lesson_management;
/
