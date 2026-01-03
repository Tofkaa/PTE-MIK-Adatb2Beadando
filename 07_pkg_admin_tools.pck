CREATE OR REPLACE PACKAGE pkg_admin_tools AS
  -- ======================================================
  -- users and logging
  -- ======================================================
  PROCEDURE log_admin_action(p_admin_id            IN RAW
                            ,p_action_type         IN VARCHAR2
                            ,p_target_user_id      IN RAW DEFAULT NULL
                            ,p_target_classroom_id IN NUMBER DEFAULT NULL
                            ,p_details             IN VARCHAR2);

  PROCEDURE suspend_user(p_admin_id IN RAW
                        ,p_user_id  IN RAW
                        ,p_reason   IN VARCHAR2);

  PROCEDURE delete_user(p_admin_id IN RAW
                       ,p_user_id  IN RAW);

  PROCEDURE reset_user_streak(p_admin_id IN RAW
                             ,p_user_id  IN RAW);

  -- ======================================================
  -- maintenance and statistics
  -- ======================================================

  PROCEDURE daily_maintenance;

  FUNCTION get_admin_activity_log(p_admin_id IN RAW) RETURN SYS_REFCURSOR;

  FUNCTION get_recent_admin_actions(p_limit NUMBER DEFAULT 50)
    RETURN SYS_REFCURSOR;

  FUNCTION get_system_statistics RETURN SYS_REFCURSOR;

  PROCEDURE remove_inactive_users(p_admin_id      IN RAW
                                 ,p_inactive_days NUMBER);

  FUNCTION get_user_stats(p_user_id IN RAW) RETURN ty_user_stats;

  FUNCTION get_top_users(p_limit IN NUMBER DEFAULT 10)
    RETURN ty_user_stats_tab;

END pkg_admin_tools;
/
CREATE OR REPLACE PACKAGE BODY pkg_admin_tools AS

  -- ======================================================
  -- LOGGING AND USER MANAGEMENT
  -- ======================================================

  PROCEDURE log_admin_action(p_admin_id            IN RAW
                            ,p_action_type         IN VARCHAR2
                            ,p_target_user_id      IN RAW DEFAULT NULL
                            ,p_target_classroom_id IN NUMBER DEFAULT NULL
                            ,p_details             IN VARCHAR2) AS
  BEGIN
    INSERT INTO admin_logs
      (log_id
      ,admin_id
      ,action_type
      ,target_user_id
      ,target_classroom_id
      ,details
      ,logged_at)
    VALUES
      (sys_guid()
      ,p_admin_id
      ,p_action_type
      ,p_target_user_id
      ,p_target_classroom_id
      ,p_details
      ,systimestamp);
  END log_admin_action;

  PROCEDURE suspend_user(p_admin_id IN RAW
                        ,p_user_id  IN RAW
                        ,p_reason   IN VARCHAR2) AS
  BEGIN
    UPDATE users SET role = 'SUSPENDED' WHERE user_id = p_user_id;
  
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'A felhasználó nem található.',
                                                'ID: ' || p_user_id,
                                                'pkg_admin_tools.suspend_user');
    END IF;
  
    log_admin_action(p_admin_id,
                     'SUSPEND_USER',
                     p_user_id,
                     NULL,
                     'Ok: ' || p_reason);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_user_id,
                                                'pkg_admin_tools.suspend_user');
  END suspend_user;

  PROCEDURE delete_user(p_admin_id IN RAW
                       ,p_user_id  IN RAW) AS
  BEGIN
    DELETE FROM users WHERE user_id = p_user_id;
  
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'A felhasználó nem található.',
                                                'ID: ' || p_user_id,
                                                'pkg_admin_tools.delete_user');
    END IF;
  
    log_admin_action(p_admin_id,
                     'DELETE_USER',
                     p_user_id,
                     NULL,
                     'Manuális törlés.');
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_user_id,
                                                'pkg_admin_tools.delete_user');
  END delete_user;

  PROCEDURE reset_user_streak(p_admin_id IN RAW
                             ,p_user_id  IN RAW) AS
  BEGIN
    pkg_progress_tracking.update_streak(p_user_id, p_success => FALSE);
    log_admin_action(p_admin_id,
                     'RESET_STREAK',
                     p_user_id,
                     NULL,
                     'Streak nullázva.');
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_user_id,
                                                'pkg_admin_tools.reset_user_streak');
  END reset_user_streak;

  -- ======================================================
  -- MAINTENANCE AND STATISTICS
  -- ======================================================

  PROCEDURE remove_inactive_users(p_admin_id      IN RAW
                                 ,p_inactive_days NUMBER) AS
    TYPE t_id_list IS TABLE OF users.user_id%TYPE;
    v_deleted_ids t_id_list;
    v_log_details VARCHAR2(4000);
  BEGIN
  
    SELECT user_id
      BULK COLLECT
      INTO v_deleted_ids
      FROM users
     WHERE last_login IS NOT NULL
       AND last_login < (systimestamp - p_inactive_days);
  
    DELETE FROM users
     WHERE last_login IS NOT NULL
       AND last_login < (systimestamp - p_inactive_days);
  
    IF v_deleted_ids.count > 0
    THEN
      v_log_details := 'Inaktív felhasználók törölve (' ||
                       v_deleted_ids.count || ' db): ';
    
      FOR i IN 1 .. v_deleted_ids.count
      LOOP
      
        IF length(v_log_details) + 35 > 3950
        THEN
          v_log_details := v_log_details || '... (többi levágva)';
          EXIT;
        END IF;
        v_log_details := v_log_details || v_deleted_ids(i) || ', ';
      END LOOP;
    
      v_log_details := rtrim(v_log_details, ', ');
    ELSE
      v_log_details := 'Nem volt törlendő inaktív felhasználó (' ||
                       p_inactive_days || ' napja inaktív).';
    END IF;
  
    log_admin_action(p_admin_id,
                     'REMOVE_INACTIVE_USERS',
                     NULL,
                     NULL,
                     v_log_details);
  
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'Days: ' || p_inactive_days,
                                                'pkg_admin_tools.remove_inactive_users');
  END remove_inactive_users;

  PROCEDURE daily_maintenance IS
  BEGIN
    DELETE FROM error_log WHERE err_time < SYSDATE - 30;
  
    DELETE FROM admin_logs WHERE logged_at < systimestamp - 365;
  
    remove_inactive_users(p_admin_id => NULL, p_inactive_days => 730);
  
    log_admin_action(NULL,
                     'SYSTEM_MAINTENANCE',
                     NULL,
                     NULL,
                     'Napi karbantartás sikeresen lefutott.');
  
  EXCEPTION
    WHEN OTHERS THEN
    
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'Daily Job',
                                                'pkg_admin_tools.daily_maintenance');
  END daily_maintenance;

  FUNCTION get_admin_activity_log(p_admin_id IN RAW) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT log_id
            ,action_type
            ,target_user_id
            ,target_classroom_id
            ,details
            ,logged_at
        FROM admin_logs
       WHERE admin_id = p_admin_id
       ORDER BY logged_at DESC;
    RETURN v_cursor;
  END get_admin_activity_log;

  FUNCTION get_recent_admin_actions(p_limit NUMBER DEFAULT 50)
    RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT *
        FROM (SELECT admin_id
                    ,action_type
                    ,details
                    ,logged_at
                FROM admin_logs
               ORDER BY logged_at DESC)
       WHERE rownum <= p_limit;
    RETURN v_cursor;
  END get_recent_admin_actions;

  FUNCTION get_system_statistics RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT (SELECT COUNT(*) FROM users) AS total_users
            ,(SELECT COUNT(*) FROM lessons) AS total_lessons
            ,(SELECT COUNT(*) FROM challenges) AS total_challenges
            ,(SELECT COUNT(*) FROM classrooms) AS total_classrooms
            ,(SELECT COUNT(*) FROM admin_logs) AS total_admin_logs
        FROM dual;
    RETURN v_cursor;
  END get_system_statistics;

  FUNCTION get_user_stats(p_user_id IN RAW) RETURN ty_user_stats AS
    v_stats              ty_user_stats;
    v_user_name          users.name%TYPE;
    v_total_lessons      NUMBER;
    v_avg_score          NUMBER;
    v_total_xp           users.xp%TYPE;
    v_achievements_count NUMBER;
    v_challenge_wins     NUMBER;
    v_challenge_losses   NUMBER;
    v_streak             users.streak%TYPE;
  BEGIN
    SELECT NAME
          ,xp
          ,streak
      INTO v_user_name
          ,v_total_xp
          ,v_streak
      FROM users
     WHERE user_id = p_user_id;
    SELECT COUNT(DISTINCT lesson_id)
      INTO v_total_lessons
      FROM progress
     WHERE user_id = p_user_id
       AND is_completed = 'Y';
    SELECT AVG(highest_score)
      INTO v_avg_score
      FROM progress
     WHERE user_id = p_user_id;
    SELECT COUNT(user_achievement_id)
      INTO v_achievements_count
      FROM user_achievements
     WHERE user_id = p_user_id;
    SELECT COUNT(challenge_id)
      INTO v_challenge_wins
      FROM challenges
     WHERE winner_id = p_user_id;
    SELECT COUNT(challenge_id)
      INTO v_challenge_losses
      FROM challenges
     WHERE (challenger_id = p_user_id OR opponent_id = p_user_id)
       AND winner_id != p_user_id
       AND winner_id IS NOT NULL;
  
    v_stats := ty_user_stats(user_id            => p_user_id,
                             user_name          => v_user_name,
                             total_lessons_done => coalesce(v_total_lessons,
                                                            0),
                             avg_score          => coalesce(v_avg_score, 0),
                             total_xp           => coalesce(v_total_xp, 0),
                             achievements_count => coalesce(v_achievements_count,
                                                            0),
                             challenge_wins     => coalesce(v_challenge_wins,
                                                            0),
                             challenge_losses   => coalesce(v_challenge_losses,
                                                            0),
                             streak             => coalesce(v_streak, 0));
    RETURN v_stats;
  EXCEPTION
    WHEN no_data_found THEN
      RETURN NULL;
  END get_user_stats;

  FUNCTION get_top_users(p_limit IN NUMBER DEFAULT 10)
    RETURN ty_user_stats_tab AS
    v_user_table ty_user_stats_tab;
  BEGIN
    SELECT pkg_admin_tools.get_user_stats(u.user_id)
      BULK COLLECT
      INTO v_user_table
      FROM (SELECT user_id
                  ,xp
              FROM users
             WHERE role != 'ADMIN'
             ORDER BY xp   DESC NULLS LAST
                     ,NAME ASC) u
     WHERE rownum <= p_limit;
    RETURN v_user_table;
  END get_top_users;

END pkg_admin_tools;
/
