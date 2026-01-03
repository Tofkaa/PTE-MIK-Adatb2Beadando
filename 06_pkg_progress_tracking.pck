CREATE OR REPLACE PACKAGE pkg_progress_tracking AS
  -- ======================================================
  -- xp and streak management
  -- ======================================================
  PROCEDURE add_xp(p_user_id IN RAW
                  ,p_points  IN NUMBER);

  PROCEDURE reset_xp(p_user_id IN RAW);

  PROCEDURE update_streak(p_user_id IN RAW
                         ,p_success IN BOOLEAN);

  FUNCTION get_user_xp(p_user_id IN RAW) RETURN NUMBER;
  FUNCTION get_user_streak(p_user_id IN RAW) RETURN NUMBER;

  -- ======================================================
  -- progress and results management
  -- ======================================================

  PROCEDURE record_lesson_completion(p_user_id   IN RAW
                                    ,p_lesson_id IN NUMBER
                                    ,p_score     IN NUMBER);

  PROCEDURE record_result(p_user_id             IN RAW
                         ,p_lesson_id           IN NUMBER
                         ,p_score               IN NUMBER
                         ,p_time_taken          IN NUMBER
                         ,p_is_challange_result IN CHAR DEFAULT 'N'
                         ,p_is_test_result      IN CHAR DEFAULT 'N'
                         ,p_correct_answers     IN NUMBER
                         ,p_total_questions     IN NUMBER);

  FUNCTION get_user_progress(p_user_id IN RAW) RETURN SYS_REFCURSOR;
  FUNCTION get_user_results(p_user_id IN RAW) RETURN SYS_REFCURSOR;
  FUNCTION get_user_lesson_statistics(p_user_id IN RAW)
    RETURN ty_lesson_performance_tab
    PIPELINED;

END pkg_progress_tracking;
/
CREATE OR REPLACE PACKAGE BODY pkg_progress_tracking AS
  -- ======================================================
  -- xp and streak management
  -- ======================================================
  PROCEDURE add_xp(p_user_id IN RAW
                  ,p_points  IN NUMBER) AS
  BEGIN
    UPDATE users SET xp = nvl(xp, 0) + p_points WHERE user_id = p_user_id;
  
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'Felhasználó nem található (XP)',
                                                'ID: ' || p_user_id,
                                                'pkg_progress_tracking.add_xp');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'Points: ' || p_points,
                                                'pkg_progress_tracking.add_xp');
  END add_xp;

  PROCEDURE reset_xp(p_user_id IN RAW) AS
  BEGIN
    UPDATE users SET xp = 0 WHERE user_id = p_user_id;
  END reset_xp;

  PROCEDURE update_streak(p_user_id IN RAW
                         ,p_success IN BOOLEAN) AS
  BEGIN
    IF p_success
    THEN
      UPDATE users
         SET streak = nvl(streak, 0) + 1
       WHERE user_id = p_user_id;
    ELSE
      UPDATE users SET streak = 0 WHERE user_id = p_user_id;
    END IF;
  
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'Felhasználó nem található (Streak)',
                                                'ID: ' || p_user_id,
                                                'pkg_progress_tracking.update_streak');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_user_id,
                                                'pkg_progress_tracking.update_streak');
  END update_streak;

  FUNCTION get_user_xp(p_user_id IN RAW) RETURN NUMBER AS
    v_xp NUMBER;
  BEGIN
    SELECT nvl(xp, 0) INTO v_xp FROM users WHERE user_id = p_user_id;
    RETURN v_xp;
  EXCEPTION
    WHEN no_data_found THEN
      RETURN 0;
  END get_user_xp;

  FUNCTION get_user_streak(p_user_id IN RAW) RETURN NUMBER AS
    v_streak NUMBER;
  BEGIN
    SELECT nvl(streak, 0)
      INTO v_streak
      FROM users
     WHERE user_id = p_user_id;
    RETURN v_streak;
  EXCEPTION
    WHEN no_data_found THEN
      RETURN 0;
  END get_user_streak;

  -- ======================================================
  -- progress and results management
  -- ======================================================

  PROCEDURE record_lesson_completion(p_user_id   IN RAW
                                    ,p_lesson_id IN NUMBER
                                    ,p_score     IN NUMBER) AS
    v_exists NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO v_exists
      FROM progress
     WHERE user_id = p_user_id
       AND lesson_id = p_lesson_id;
  
    IF v_exists = 0
    THEN
      INSERT INTO progress
        (progress_id
        ,user_id
        ,lesson_id
        ,completed_at
        ,highest_score
        ,last_attempt_at
        ,is_completed)
      VALUES
        (sys_guid()
        ,p_user_id
        ,p_lesson_id
        ,CASE WHEN p_score >= 50 THEN systimestamp ELSE NULL END
        ,p_score
        ,systimestamp
        ,CASE WHEN p_score >= 50 THEN 'Y' ELSE 'N' END);
    ELSE
      UPDATE progress
         SET highest_score   = greatest(nvl(highest_score, 0), p_score)
            ,completed_at = CASE
                              WHEN p_score >= 50 THEN
                               systimestamp
                              ELSE
                               completed_at
                            END
            ,last_attempt_at = systimestamp
            ,is_completed = CASE
                              WHEN p_score >= 50 THEN
                               'Y'
                              ELSE
                               'N'
                            END
       WHERE user_id = p_user_id
         AND lesson_id = p_lesson_id;
    END IF;
    pkg_progress_tracking.add_xp(p_user_id, p_score / 10);
  END record_lesson_completion;

  PROCEDURE record_result(p_user_id             IN RAW
                         ,p_lesson_id           IN NUMBER
                         ,p_score               IN NUMBER
                         ,p_time_taken          IN NUMBER
                         ,p_is_challange_result IN CHAR DEFAULT 'N'
                         ,p_is_test_result      IN CHAR DEFAULT 'N'
                         ,p_correct_answers     IN NUMBER
                         ,p_total_questions     IN NUMBER) AS
  BEGIN
  
    IF p_score < 0
       OR p_score > 100
    THEN
      pkg_exception_handler.handle_custom_error('INVALID_PARAM',
                                                'A pontszámnak 0 és 100 között kell lennie!',
                                                'Score: ' || p_score,
                                                'pkg_progress_tracking.record_result');
    END IF;
  
    INSERT INTO results
      (result_id
      ,user_id
      ,lesson_id
      ,score
      ,time_taken
      ,submitted_at
      ,is_challenge_result
      ,is_test_result
      ,correct_answers_count
      ,total_questions_count)
    VALUES
      (sys_guid()
      ,p_user_id
      ,p_lesson_id
      ,p_score
      ,p_time_taken
      ,systimestamp
      ,p_is_challange_result
      ,p_is_test_result
      ,p_correct_answers
      ,p_total_questions);
    pkg_progress_tracking.record_lesson_completion(p_user_id,
                                                   p_lesson_id,
                                                   p_score);
  
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'UID: ' || p_user_id ||
                                                ' LID: ' || p_lesson_id,
                                                'pkg_progress_tracking.record_result');
  END record_result;

  FUNCTION get_user_progress(p_user_id IN RAW) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT p.progress_id
            ,p.lesson_id
            ,l.title AS lesson_title
            ,p.highest_score
            ,p.is_completed
            ,p.completed_at
            ,p.last_attempt_at
        FROM progress p
        JOIN lessons l
          ON p.lesson_id = l.lesson_id
       WHERE p.user_id = p_user_id
       ORDER BY p.last_attempt_at DESC;
    RETURN v_cursor;
  END get_user_progress;

  FUNCTION get_user_results(p_user_id IN RAW) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT r.result_id
            ,r.lesson_id
            ,l.title AS lesson_title
            ,r.score
            ,r.time_taken
            ,r.submitted_at
            ,r.correct_answers_count
            ,r.total_questions_count
        FROM results r
        JOIN lessons l
          ON r.lesson_id = l.lesson_id
       WHERE r.user_id = p_user_id
       ORDER BY r.submitted_at DESC;
    RETURN v_cursor;
  END get_user_results;

  FUNCTION get_user_lesson_statistics(p_user_id IN RAW)
    RETURN ty_lesson_performance_tab
    PIPELINED AS
  BEGIN
    FOR rec IN (SELECT l.lesson_id
                      ,l.title AS lesson_title
                      ,nvl(AVG(r.score), 0) AS avg_score
                      ,COUNT(r.result_id) AS attempt_count
                      ,CASE
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
                       END AS completion_rate
                  FROM lessons l
                  LEFT JOIN results r
                    ON l.lesson_id = r.lesson_id
                   AND r.user_id = p_user_id
                  LEFT JOIN progress p
                    ON p.lesson_id = l.lesson_id
                   AND p.user_id = p_user_id
                 GROUP BY l.lesson_id
                         ,l.title
                 ORDER BY l.lesson_id)
    LOOP
      PIPE ROW(ty_lesson_performance(rec.lesson_id,
                                     rec.lesson_title,
                                     rec.avg_score,
                                     rec.attempt_count,
                                     rec.completion_rate));
    END LOOP;
  
    RETURN;
  END get_user_lesson_statistics;

END pkg_progress_tracking;
/
