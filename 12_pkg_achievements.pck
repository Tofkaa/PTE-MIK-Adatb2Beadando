CREATE OR REPLACE PACKAGE pkg_achievements AS
  -- ======================================================
  -- achievement management handling
  -- ======================================================

  PROCEDURE create_achievement(p_name        IN VARCHAR2
                              ,p_description IN VARCHAR2
                              ,p_criteria    IN VARCHAR2
                              ,p_icon_url    IN VARCHAR2);

  PROCEDURE update_achievement(p_achievement_id IN NUMBER
                              ,p_name           IN VARCHAR2
                              ,p_description    IN VARCHAR2
                              ,p_criteria       IN VARCHAR2
                              ,p_icon_url       IN VARCHAR2);

  PROCEDURE delete_achievement(p_achievement_id IN NUMBER);

  FUNCTION get_all_achievements RETURN SYS_REFCURSOR;
  FUNCTION get_achievement_details(p_achievement_id IN NUMBER)
    RETURN SYS_REFCURSOR;

  -- ======================================================
  -- achievement and users interaction
  -- ======================================================

  PROCEDURE grant_achievement(p_user_id        IN RAW
                             ,p_achievement_id IN NUMBER);

  FUNCTION has_achievement(p_user_id        IN RAW
                          ,p_achievement_id IN NUMBER) RETURN BOOLEAN;

  FUNCTION get_user_achievements(p_user_id IN RAW) RETURN SYS_REFCURSOR;

END pkg_achievements;
/
CREATE OR REPLACE PACKAGE BODY pkg_achievements AS

  -- ======================================================
  -- ACHIEVEMENT MANAGEMENT HANDLING
  -- ======================================================

  PROCEDURE create_achievement(p_name        IN VARCHAR2
                              ,p_description IN VARCHAR2
                              ,p_criteria    IN VARCHAR2
                              ,p_icon_url    IN VARCHAR2) AS
  BEGIN
    INSERT INTO achievements
      (NAME
      ,description
      ,criteria
      ,icon_url)
    VALUES
      (p_name
      ,p_description
      ,p_criteria
      ,p_icon_url);
  
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'Name: ' || p_name,
                                                'pkg_achievements.create_achievement');
  END create_achievement;

  PROCEDURE update_achievement(p_achievement_id IN NUMBER
                              ,p_name           IN VARCHAR2
                              ,p_description    IN VARCHAR2
                              ,p_criteria       IN VARCHAR2
                              ,p_icon_url       IN VARCHAR2) AS
  BEGIN
    UPDATE achievements
       SET NAME        = p_name
          ,description = p_description
          ,criteria    = p_criteria
          ,icon_url    = p_icon_url
     WHERE achievement_id = p_achievement_id;
  
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error(p_error_name => 'RECORD_NOT_FOUND',
                                                p_message    => 'A megadott achievement nem található.',
                                                p_context    => 'ID: ' ||
                                                                p_achievement_id,
                                                p_api_name   => 'pkg_achievements.update_achievement');
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_achievement_id,
                                                'pkg_achievements.update_achievement');
  END update_achievement;

  PROCEDURE delete_achievement(p_achievement_id IN NUMBER) AS
  BEGIN
    DELETE FROM achievements WHERE achievement_id = p_achievement_id;
  
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error(p_error_name => 'RECORD_NOT_FOUND',
                                                p_message    => 'A megadott achievement nem található.',
                                                p_context    => 'ID: ' ||
                                                                p_achievement_id,
                                                p_api_name   => 'pkg_achievements.delete_achievement');
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_achievement_id,
                                                'pkg_achievements.delete_achievement');
  END delete_achievement;

  FUNCTION get_all_achievements RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT achievement_id
            ,NAME
            ,description
            ,criteria
            ,icon_url
        FROM achievements
       ORDER BY NAME;
    RETURN v_cursor;
  END get_all_achievements;

  FUNCTION get_achievement_details(p_achievement_id IN NUMBER)
    RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT achievement_id
            ,NAME
            ,description
            ,criteria
            ,icon_url
        FROM achievements
       WHERE achievement_id = p_achievement_id;
    RETURN v_cursor;
  END get_achievement_details;

  -- ======================================================
  -- ACHIEVEMENT AND USERS INTERACTION
  -- ======================================================
  PROCEDURE grant_achievement(p_user_id        IN RAW
                             ,p_achievement_id IN NUMBER) AS
  BEGIN
    IF has_achievement(p_user_id, p_achievement_id)
    THEN
      RETURN;
    END IF;
  
    INSERT INTO user_achievements
      (user_id
      ,achievement_id
      ,achieved_at)
    VALUES
      (p_user_id
      ,p_achievement_id
      ,systimestamp);
  
    pkg_progress_tracking.add_xp(p_user_id => p_user_id, p_points => 20);
  
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'User: ' || p_user_id ||
                                                ', Ach: ' ||
                                                p_achievement_id,
                                                'pkg_achievements.grant_achievement');
  END grant_achievement;

  FUNCTION has_achievement(p_user_id        IN RAW
                          ,p_achievement_id IN NUMBER) RETURN BOOLEAN AS
    v_exists NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO v_exists
      FROM user_achievements
     WHERE user_id = p_user_id
       AND achievement_id = p_achievement_id;
  
    RETURN(v_exists > 0);
  END has_achievement;

  FUNCTION get_user_achievements(p_user_id IN RAW) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT a.achievement_id
            ,a.name
            ,a.description
            ,a.icon_url
            ,ua.achieved_at
        FROM user_achievements ua
        JOIN achievements a
          ON ua.achievement_id = a.achievement_id
       WHERE ua.user_id = p_user_id
       ORDER BY ua.achieved_at DESC;
    RETURN v_cursor;
  END get_user_achievements;

END pkg_achievements;
/
