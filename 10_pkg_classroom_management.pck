CREATE OR REPLACE PACKAGE pkg_classroom_management AS

  -- ======================================================
  -- CLASSROOMS MANAGEMENT
  -- ======================================================
  PROCEDURE create_classroom(p_name        IN VARCHAR2
                            ,p_description IN VARCHAR2
                            ,p_created_by  IN RAW
                            ,p_invite_code IN VARCHAR2 DEFAULT NULL);
  PROCEDURE update_classroom(p_classroom_id   IN NUMBER
                            ,p_classroom_name IN VARCHAR2
                            ,p_description    IN VARCHAR2);
  PROCEDURE delete_classroom(p_classroom_id IN NUMBER);
  FUNCTION get_all_classrooms RETURN SYS_REFCURSOR;
  FUNCTION get_classroom_by_id(p_classroom_id IN NUMBER) RETURN SYS_REFCURSOR;

  -- ======================================================
  -- CLASSROOM MEMBERS MANAGEMENT
  -- ======================================================

  PROCEDURE add_member_to_classroom(p_classroom_id IN NUMBER
                                   ,p_user_id      IN RAW);

  PROCEDURE remove_member_from_classroom(p_classroom_id IN NUMBER
                                        ,p_user_id      IN RAW);
  FUNCTION get_members_by_classroom(p_classroom_id IN NUMBER)
    RETURN SYS_REFCURSOR;

  FUNCTION is_user_in_classroom(p_classroom_id IN NUMBER
                               ,p_user_id      IN RAW) RETURN BOOLEAN;
END pkg_classroom_management;
/
CREATE OR REPLACE PACKAGE BODY pkg_classroom_management AS
  -- ======================================================
  -- CLASSROOMS
  -- ======================================================
  PROCEDURE create_classroom(p_name        IN VARCHAR2
                            ,p_description IN VARCHAR2
                            ,p_created_by  IN RAW
                            ,p_invite_code IN VARCHAR2 DEFAULT NULL) AS
  BEGIN
    INSERT INTO classrooms
      (NAME
      ,description
      ,teacher_id
      ,created_at
      ,invite_code)
    VALUES
      (p_name
      ,p_description
      ,p_created_by
      ,systimestamp
      ,p_invite_code);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'Name: ' || p_name,
                                                'pkg_classroom_management.create_classroom');
  END;

  PROCEDURE update_classroom(p_classroom_id   IN NUMBER
                            ,p_classroom_name IN VARCHAR2
                            ,p_description    IN VARCHAR2) AS
  BEGIN
    UPDATE classrooms
       SET NAME        = p_classroom_name
          ,description = p_description
     WHERE classroom_id = p_classroom_id;
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'Osztályterem nem található',
                                                'ID: ' || p_classroom_id,
                                                'pkg_classroom_management.update_classroom');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_classroom_id,
                                                'pkg_classroom_management.update_classroom');
  END;

  PROCEDURE delete_classroom(p_classroom_id IN NUMBER) AS
  BEGIN
    DELETE FROM classrooms WHERE classroom_id = p_classroom_id;
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'Osztályterem nem található',
                                                'ID: ' || p_classroom_id,
                                                'pkg_classroom_management.update_classroom');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_classroom_id,
                                                'pkg_classroom_management.update_classroom');
  END;

  FUNCTION get_all_classrooms RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT classroom_id
            ,NAME
            ,description
            ,teacher_id
            ,created_at
        FROM classrooms
       ORDER BY created_at DESC;
    RETURN v_cursor;
  END get_all_classrooms;

  FUNCTION get_classroom_by_id(p_classroom_id IN NUMBER) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT classroom_id
            ,NAME
            ,description
            ,teacher_id
            ,created_at
        FROM classrooms
       WHERE classroom_id = p_classroom_id;
    RETURN v_cursor;
  END get_classroom_by_id;

  -- ======================================================
  -- CLASSROOM MEMBERS
  -- ======================================================
  PROCEDURE add_member_to_classroom(p_classroom_id IN NUMBER
                                   ,p_user_id      IN RAW) AS
  BEGIN
    IF is_user_in_classroom(p_classroom_id, p_user_id)
    THEN
    
      pkg_exception_handler.handle_custom_error(p_error_name => 'DUPLICATE_RECORD',
                                                p_message    => 'A felhasználó már hozzá van rendelve ehhez az osztályhoz.',
                                                p_context    => 'ClassID: ' ||
                                                                p_classroom_id ||
                                                                ', UserID: ' ||
                                                                p_user_id,
                                                p_api_name   => 'pkg_classroom_management.add_member_to_classroom');
    
    ELSE
      INSERT INTO classroom_members
        (classroom_id
        ,user_id
        ,joined_at)
      VALUES
        (p_classroom_id
        ,p_user_id
        ,systimestamp);
    
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ClassID: ' ||
                                                p_classroom_id,
                                                'pkg_classroom_management.add_member_to_classroom');
  END add_member_to_classroom;

  PROCEDURE remove_member_from_classroom(p_classroom_id IN NUMBER
                                        ,p_user_id      IN RAW) AS
  BEGIN
    DELETE FROM classroom_members
     WHERE classroom_id = p_classroom_id
       AND user_id = p_user_id;
    IF SQL%ROWCOUNT = 0
    THEN
      pkg_exception_handler.handle_custom_error('RECORD_NOT_FOUND',
                                                'Tag nem található az osztályban',
                                                'ClassID: ' ||
                                                p_classroom_id,
                                                'pkg_classroom_management.remove_member');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_exception_handler.handle_system_error(SQLCODE,
                                                SQLERRM,
                                                'ID: ' || p_classroom_id,
                                                'pkg_classroom_management.remove_member');
  END;

  FUNCTION get_members_by_classroom(p_classroom_id IN NUMBER)
    RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT cm.classroom_member_id
            ,cm.user_id
            ,u.name
            ,u.role
            ,cm.joined_at
        FROM classroom_members cm
        JOIN users u
          ON cm.user_id = u.user_id
       WHERE cm.classroom_id = p_classroom_id
       ORDER BY cm.joined_at;
    RETURN v_cursor;
  END get_members_by_classroom;

  FUNCTION is_user_in_classroom(p_classroom_id IN NUMBER
                               ,p_user_id      IN RAW) RETURN BOOLEAN AS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM classroom_members
     WHERE classroom_id = p_classroom_id
       AND user_id = p_user_id;
    RETURN v_count > 0;
  END is_user_in_classroom;

END pkg_classroom_management;
/
