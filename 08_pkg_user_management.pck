-- ======================================================
-- user management package
-- ======================================================
CREATE OR REPLACE PACKAGE pkg_user_management AS
  PROCEDURE add_user(p_name               IN VARCHAR2
                    ,p_email              IN VARCHAR2
                    ,p_role               IN VARCHAR2
                    ,p_profile_picture    IN VARCHAR2 DEFAULT NULL
                    ,p_preferred_language IN VARCHAR2 DEFAULT 'HU');

  FUNCTION get_user_stats_json(p_user_id IN RAW) RETURN VARCHAR2;

END pkg_user_management;
/
CREATE OR REPLACE PACKAGE BODY pkg_user_management AS

  ------------------------------------------------------------------------------
  -- Új felhasználó beszúrása
  ------------------------------------------------------------------------------
  PROCEDURE add_user(p_name               IN VARCHAR2
                    ,p_email              IN VARCHAR2
                    ,p_role               IN VARCHAR2
                    ,p_profile_picture    IN VARCHAR2 DEFAULT NULL
                    ,p_preferred_language IN VARCHAR2 DEFAULT 'HU') AS
  BEGIN
    INSERT INTO users
      (user_id
      ,NAME
      ,email
      ,password_hash
      ,role
      ,xp
      ,streak
      ,created_at
      ,profile_picture_url
      ,preferred_language)
    VALUES
      (sys_guid()
      ,p_name
      ,p_email
      ,'default_hash_123'
      ,p_role
      ,0
      ,0
      ,systimestamp
      ,p_profile_picture
      ,p_preferred_language);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'Email: ' || p_email,
                                                'pkg_user_management.add_user');
  END add_user;

  ------------------------------------------------------------------------------
  -- Felhasználói statisztika lekérdezés
  ------------------------------------------------------------------------------
  FUNCTION get_user_stats_json(p_user_id IN RAW) RETURN VARCHAR2 AS
    v_obj  ty_user_stats;
    v_json VARCHAR2(32767);
  
    FUNCTION json_escape(p_str IN VARCHAR2) RETURN VARCHAR2 IS
      v_temp VARCHAR2(32767) := p_str;
    BEGIN
      IF v_temp IS NULL
      THEN
        RETURN '';
      END IF;
    
      v_temp := REPLACE(v_temp, '\', '\\');
    
      v_temp := REPLACE(v_temp, '"', '\"');
    
      v_temp := REPLACE(v_temp, chr(10), '\n');
      v_temp := REPLACE(v_temp, chr(13), '\r');
      v_temp := REPLACE(v_temp, chr(9), '\t');
      v_temp := REPLACE(v_temp, chr(8), '\b');
      v_temp := REPLACE(v_temp, chr(12), '\f');
    
      RETURN v_temp;
    END json_escape;
  
  BEGIN
  
    v_obj := pkg_admin_tools.get_user_stats(p_user_id);
  
    IF v_obj IS NULL
    THEN
      RETURN '{}';
    END IF;
  
    v_json := '{' || '"user_id":"' || v_obj.user_id || '",' ||
              '"user_name":"' || json_escape(v_obj.user_name) || '",' ||
              '"total_lessons_done":' || nvl(v_obj.total_lessons_done, 0) || ',' ||
              '"avg_score":' || nvl(v_obj.avg_score, 0) || ',' ||
              '"total_xp":' || nvl(v_obj.total_xp, 0) || ',' ||
              '"achievements_count":' || nvl(v_obj.achievements_count, 0) || ',' ||
              '"challenge_wins":' || nvl(v_obj.challenge_wins, 0) || ',' ||
              '"challenge_losses":' || nvl(v_obj.challenge_losses, 0) || ',' ||
              '"streak":' || nvl(v_obj.streak, 0) || '}';
  
    RETURN v_json;
  END get_user_stats_json;

END pkg_user_management;
/
