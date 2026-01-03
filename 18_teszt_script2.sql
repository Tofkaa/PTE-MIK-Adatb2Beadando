DECLARE
    -- Változók az ID-k lekérdezéséhez
    v_admin_id      RAW(16);
    v_student1_id   RAW(16);
    v_student2_id   RAW(16);
    v_lesson_id     NUMBER;
    
    -- Változók a logok ellenőrzéséhez
    v_err_count_before NUMBER;
    v_err_count_after  NUMBER;
    v_admin_log_count  NUMBER;
    
    -- Teszt segédváltozók
    v_test_name     VARCHAR2(100);
  
    PROCEDURE print_result(p_test_name VARCHAR2, p_success BOOLEAN, p_message VARCHAR2 DEFAULT NULL) IS
    BEGIN
        IF p_success THEN
            DBMS_OUTPUT.PUT_LINE('[OK] ' || p_test_name);

            IF p_message IS NOT NULL THEN
               DBMS_OUTPUT.PUT_LINE('       -> Info: ' || p_message);
            END IF;
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] !!! ' || p_test_name || ' !!!');
            IF p_message IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('       -> Hiba oka: ' || p_message);
            END IF;
        END IF;
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('===================================================');
    DBMS_OUTPUT.PUT_LINE('   RENDSZER INTEGRITÁS ÉS HIBAKEZELÉS TESZTELÉSE   ');
    DBMS_OUTPUT.PUT_LINE('===================================================');

    -- 1. Előkészületek
    BEGIN
        SELECT user_id INTO v_admin_id FROM users WHERE email = 'admin@lms.com';
        SELECT user_id INTO v_student1_id FROM users WHERE email = 'student1@lms.com';
        SELECT user_id INTO v_student2_id FROM users WHERE email = 'student2@lms.com';
        SELECT lesson_id INTO v_lesson_id FROM lessons WHERE rownum = 1;
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('!!! KRITIKUS HIBA: Nem találhatók a tesztadatok (Seed script lefutott?)');
            RETURN;
    END;

    SELECT COUNT(*) INTO v_err_count_before FROM error_log;

    -- =========================================================================
    -- TESZT 1: DUPLICATE_RECORD (-20002)
    -- =========================================================================
    v_test_name := 'Teszt 1: Duplikált Email kezelése';
    BEGIN
        pkg_user_management.add_user('Fake Admin', 'admin@lms.com', 'STUDENT');
        print_result(v_test_name, FALSE, 'Nem dobott hibát duplikációra!');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20002 THEN
                print_result(v_test_name, TRUE, 'Siker! Elkapott kód: ORA-20002 (DUPLICATE_RECORD)');
            ELSE
                print_result(v_test_name, FALSE, 'Rossz hibakód: ' || SQLCODE || ' - ' || SQLERRM);
            END IF;
    END;

    -- =========================================================================
    -- TESZT 2: RECORD_NOT_FOUND (-20001)
    -- =========================================================================
    v_test_name := 'Teszt 2: Nem létező rekord frissítése';
    BEGIN
        pkg_lesson_management.update_lesson(
            p_lesson_id => 999999, 
            p_title => 'Ghost Lesson',
            p_difficulty => 'HARD',
            p_language => 'EN',
            p_description => 'Test'
        );
        print_result(v_test_name, FALSE, 'Nem dobott hibát nem létező ID-ra!');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20001 THEN
                print_result(v_test_name, TRUE, 'Siker! Elkapott kód: ORA-20001 (RECORD_NOT_FOUND)');
            ELSE
                print_result(v_test_name, FALSE, 'Rossz hibakód: ' || SQLCODE || ' - ' || SQLERRM);
            END IF;
    END;

    -- =========================================================================
    -- TESZT 3: BUSINESS_RULE (-20003)
    -- =========================================================================
    v_test_name := 'Teszt 3: Üzleti szabály (Önkihívás)';
    BEGIN
        pkg_challenge_system.create_challange(v_student1_id, v_student1_id, v_lesson_id);
        print_result(v_test_name, FALSE, 'Nem dobott hibát önkihívásra!');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20003 THEN
                print_result(v_test_name, TRUE, 'Siker! Elkapott kód: ORA-20003 (BUSINESS_RULE)');
            ELSE
                print_result(v_test_name, FALSE, 'Rossz hibakód: ' || SQLCODE || ' - ' || SQLERRM);
            END IF;
    END;

    -- =========================================================================
    -- TESZT 4: INVALID_PARAM (-20004)
    -- =========================================================================
    v_test_name := 'Teszt 4: Érvénytelen paraméter (Score 150)';
    BEGIN
        pkg_progress_tracking.record_result(v_student1_id, v_lesson_id, 150, 60, 'N', 'N', 10, 10);
        print_result(v_test_name, FALSE, 'Nem dobott hibát hibás pontszámra!');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20004 THEN
                print_result(v_test_name, TRUE, 'Siker! Elkapott kód: ORA-20004 (INVALID_PARAM)');
            ELSE
                print_result(v_test_name, FALSE, 'Rossz hibakód: ' || SQLCODE || ' - ' || SQLERRM);
            END IF;
    END;

    -- =========================================================================
    -- TESZT 5: ADMIN LOGOLÁS (Siker)
    -- =========================================================================
    v_test_name := 'Teszt 5: Admin művelet és logolás';
    BEGIN
        pkg_admin_tools.suspend_user(v_admin_id, v_student2_id, 'Tesztelés miatt.');
        
        SELECT COUNT(*) INTO v_admin_log_count 
          FROM admin_logs 
         WHERE action_type = 'SUSPEND_USER' 
           AND target_user_id = v_student2_id;
           
        IF v_admin_log_count > 0 THEN
            print_result(v_test_name, TRUE, 'Admin log bejegyzés sikeresen létrejött.');
        ELSE
            print_result(v_test_name, FALSE, 'Nincs nyoma az admin logban!');
        END IF;
        
        ROLLBACK; -- Visszacsináljuk
    EXCEPTION
        WHEN OTHERS THEN
            print_result(v_test_name, FALSE, 'Hiba történt: ' || SQLERRM);
            ROLLBACK;
    END;

    -- =========================================================================
    -- TESZT 6: ERROR LOG VALIDÁCIÓ
    -- =========================================================================
    v_test_name := 'Teszt 6: Error Log ellenőrzése';
    
    SELECT COUNT(*) INTO v_err_count_after FROM error_log;
    
    IF v_err_count_after >= v_err_count_before + 4 THEN
        print_result(v_test_name, TRUE, 'A logok száma ' || v_err_count_before || '-ról ' || v_err_count_after || '-ra nőtt (+4 elvárás).');
    ELSE
        print_result(v_test_name, FALSE, 'Nem került be elég hiba a logba! (Delta: ' || (v_err_count_after - v_err_count_before) || ')');
    END IF;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- MINTA A LOGBÓL (Utolsó 3 bejegyzés) ---');
    FOR r IN (
        SELECT err_message, err_value 
          FROM (SELECT err_message, err_value FROM error_log ORDER BY err_time DESC)
         WHERE rownum <= 3
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('LOG: ' || r.err_message || ' | Context: ' || r.err_value);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== TESZTELÉS VÉGE ===');

END;
/
