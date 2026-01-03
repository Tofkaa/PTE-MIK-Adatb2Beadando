CREATE OR REPLACE PACKAGE pkg_challenge_system AS
  -- ======================================================
  -- challange creation and management
  -- ======================================================
  PROCEDURE create_challange(p_challanger_id IN RAW
                            ,p_opponent_id   IN RAW
                            ,p_lesson_id     IN NUMBER);
  PROCEDURE update_challange_status(p_challange_id IN RAW
                                   ,p_status       IN VARCHAR2);
  PROCEDURE complete_challange(p_challange_id IN RAW
                              ,p_winner_id    IN RAW);
  -- ======================================================
  -- results and statistics
  -- ======================================================
  PROCEDURE record_challange_result(p_challange_id    IN RAW
                                   ,p_user_id         IN RAW
                                   ,p_lesson_id       IN NUMBER
                                   ,p_score           IN NUMBER
                                   ,p_time_taken      IN NUMBER
                                   ,p_correct_answers IN NUMBER
                                   ,p_total_questions IN NUMBER);
  FUNCTION get_active_challanges(p_user_id IN RAW) RETURN SYS_REFCURSOR;
  FUNCTION get_completed_challanges(p_user_id IN RAW) RETURN SYS_REFCURSOR;
  FUNCTION get_challange_details(p_challange_id IN RAW) RETURN SYS_REFCURSOR;

END pkg_challenge_system;
/
CREATE OR REPLACE PACKAGE BODY pkg_challenge_system AS
  -- ======================================================
  -- CHALLENGE CREATION AND MANAGEMENT
  -- ======================================================

  PROCEDURE create_challange(p_challanger_id IN RAW
                            ,p_opponent_id   IN RAW
                            ,p_lesson_id     IN NUMBER) AS
  BEGIN
    IF p_challanger_id = p_opponent_id
    THEN
      pkg_exception_handler.handle_custom_error(p_error_name => 'BUSINESS_RULE',
                                                p_message    => 'Nem hívhatod ki saját magadat!',
                                                p_context    => 'ID: ' ||
                                                                p_challanger_id,
                                                p_api_name   => 'pkg_challenge_system.create_challange');
    END IF;
  
    INSERT INTO challenges
      (challenge_id
      ,challenger_id
      ,opponent_id
      ,lesson_id
      ,start_time
      ,status)
    VALUES
      (sys_guid()
      ,p_challanger_id
      ,p_opponent_id
      ,p_lesson_id
      ,systimestamp
      ,'PENDING');
  
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'Challenger: ' ||
                                                p_challanger_id ||
                                                ', Opponent: ' ||
                                                p_opponent_id,
                                                'pkg_challenge_system.create_challange');
  END create_challange;

  PROCEDURE update_challange_status(p_challange_id IN RAW
                                   ,p_status       IN VARCHAR2) AS
  BEGIN
    UPDATE challenges
       SET status = p_status
     WHERE challenge_id = p_challange_id;
  
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error(p_error_name => 'RECORD_NOT_FOUND',
                                                p_message    => 'A kihívás nem található.',
                                                p_context    => 'ID: ' ||
                                                                p_challange_id,
                                                p_api_name   => 'pkg_challenge_system.update_challange_status');
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_challange_id,
                                                'pkg_challenge_system.update_challange_status');
  END update_challange_status;

  PROCEDURE complete_challange(p_challange_id IN RAW
                              ,p_winner_id    IN RAW) AS
  BEGIN
    UPDATE challenges
       SET winner_id = p_winner_id
          ,end_time  = systimestamp
          ,status    = 'COMPLETED'
     WHERE challenge_id = p_challange_id;
  
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error(p_error_name => 'RECORD_NOT_FOUND',
                                                p_message    => 'A lezárandó kihívás nem található.',
                                                p_context    => 'ID: ' ||
                                                                p_challange_id,
                                                p_api_name   => 'pkg_challenge_system.complete_challange');
    END IF;
  
    pkg_progress_tracking.add_xp(p_winner_id, 50);
  
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_challange_id ||
                                                ', Winner: ' || p_winner_id,
                                                'pkg_challenge_system.complete_challange');
  END complete_challange;

  -- ======================================================
  -- RESULTS AND STATISTICS
  -- ======================================================

  PROCEDURE record_challange_result(p_challange_id    IN RAW
                                   ,p_user_id         IN RAW
                                   ,p_lesson_id       IN NUMBER
                                   ,p_score           IN NUMBER
                                   ,p_time_taken      IN NUMBER
                                   ,p_correct_answers IN NUMBER
                                   ,p_total_questions IN NUMBER) AS
  BEGIN
    INSERT INTO results
      (result_id
      ,user_id
      ,lesson_id
      ,score
      ,time_taken
      ,submitted_at
      ,is_challenge_result
      ,challenge_id
      ,correct_answers_count
      ,total_questions_count)
    VALUES
      (sys_guid()
      ,p_user_id
      ,p_lesson_id
      ,p_score
      ,p_time_taken
      ,systimestamp
      ,'Y'
      ,p_challange_id
      ,p_correct_answers
      ,p_total_questions);
  
    pkg_progress_tracking.add_xp(p_user_id, p_score / 20);
  
    pkg_progress_tracking.record_lesson_completion(p_user_id,
                                                   p_lesson_id,
                                                   p_score);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ChallangeID: ' ||
                                                p_challange_id ||
                                                ', User: ' || p_user_id,
                                                'pkg_challenge_system.record_challange_result');
  END record_challange_result;

  FUNCTION get_active_challanges(p_user_id IN RAW) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT c.challenge_id
            ,u1.name        AS challenger_name
            ,u2.name        AS opponent_name
            ,l.title        AS lesson_title
            ,c.status
            ,c.start_time
        FROM challenges c
        JOIN users u1
          ON c.challenger_id = u1.user_id
        JOIN users u2
          ON c.opponent_id = u2.user_id
        JOIN lessons l
          ON c.lesson_id = l.lesson_id
       WHERE (c.challenger_id = p_user_id OR c.opponent_id = p_user_id)
         AND c.status IN ('PENDING', 'IN_PROGRESS')
       ORDER BY c.start_time DESC;
    RETURN v_cursor;
  END get_active_challanges;

  FUNCTION get_completed_challanges(p_user_id IN RAW) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT c.challenge_id
            ,u1.name        AS challenger_name
            ,u2.name        AS opponent_name
            ,w.name         AS winner_name
            ,l.title        AS lesson_title
            ,c.start_time
            ,c.end_time
        FROM challenges c
        JOIN users u1
          ON c.challenger_id = u1.user_id
        JOIN users u2
          ON c.opponent_id = u2.user_id
        JOIN lessons l
          ON c.lesson_id = l.lesson_id
        LEFT JOIN users w
          ON c.winner_id = w.user_id
       WHERE (c.challenger_id = p_user_id OR c.opponent_id = p_user_id)
         AND c.status = 'COMPLETED'
       ORDER BY c.end_time DESC;
    RETURN v_cursor;
  END get_completed_challanges;

  FUNCTION get_challange_details(p_challange_id IN RAW) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT c.challenge_id
            ,u1.name        AS challenger_name
            ,u2.name        AS opponent_name
            ,w.name         AS winner_name
            ,l.title        AS lesson_title
            ,c.status
            ,c.start_time
            ,c.end_time
        FROM challenges c
        JOIN users u1
          ON c.challenger_id = u1.user_id
        JOIN users u2
          ON c.opponent_id = u2.user_id
        JOIN lessons l
          ON c.lesson_id = l.lesson_id
        LEFT JOIN users w
          ON c.winner_id = w.user_id
       WHERE c.challenge_id = p_challange_id;
    RETURN v_cursor;
  END get_challange_details;

END pkg_challenge_system;
/
