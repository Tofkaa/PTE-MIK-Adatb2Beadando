
DECLARE
    -- Változók a tesztekhez
    v_count_before NUMBER;
    v_count_after  NUMBER;
    v_user_id      RAW(16);
    v_user_name    VARCHAR2(100);
    v_class_id     NUMBER;
    v_dummy_id     NUMBER;
    v_cursor       SYS_REFCURSOR;
    
    -- Kivételek kezeléséhez (ha szükséges)
    v_err_msg      VARCHAR2(4000);

    -- Segédeljárás a szép formázáshoz
    PROCEDURE print_header(p_text VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        DBMS_OUTPUT.PUT_LINE('================================================================');
        DBMS_OUTPUT.PUT_LINE('  TESZT: ' || p_text);
        DBMS_OUTPUT.PUT_LINE('================================================================');
    END;

    PROCEDURE assert(p_condition BOOLEAN, p_success_msg VARCHAR2, p_fail_msg VARCHAR2) IS
    BEGIN
        IF p_condition THEN
            DBMS_OUTPUT.PUT_LINE('[OK] ' || p_success_msg);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] !!! ' || p_fail_msg || ' !!!');
        END IF;
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Rendszer Tesztelés Indítása: ' || SYSTIMESTAMP);

    -- =========================================================================
    -- 1. ALAP ADATOK ELLENŐRZÉSE
    -- =========================================================================
    print_header('1. ADATINTEGRITÁS ÉS FELTÖLTÖTTSÉG');
    
    SELECT COUNT(*) INTO v_count_after FROM users;
    assert(v_count_after >= 10, 'Felhasználók száma megfelelő (' || v_count_after || ')', 'Kevés felhasználó van a rendszerben!');

    SELECT COUNT(*) INTO v_count_after FROM lessons;
    assert(v_count_after > 0, 'Leckék betöltve (' || v_count_after || ')', 'Nincsenek leckék!');

    SELECT COUNT(*) INTO v_count_after FROM results;
    assert(v_count_after > 0, 'Eredmények generálva (' || v_count_after || ')', 'Nincsenek eredmények!');

    -- =========================================================================
    -- 2. TÍPUSOK ÉS PIPELINED FÜGGVÉNYEK
    -- =========================================================================
    print_header('2. PIPELINED FÜGGVÉNY (ty_lesson_performance)');
    
    DBMS_OUTPUT.PUT_LINE('Lecke statisztikák lekérdezése a package-ből:');
    v_count_after := 0;
    
    FOR r IN (SELECT * FROM TABLE(pkg_lesson_management.get_all_lesson_statistics)) LOOP
        DBMS_OUTPUT.PUT_LINE(' -> Lecke: ' || RPAD(r.lesson_title, 20) || 
                             ' | Átlag: ' || TO_CHAR(r.avg_score, '990.99') || 
                             ' | Kitöltések: ' || r.attempt_count);
        v_count_after := v_count_after + 1;
    END LOOP;
    
    assert(v_count_after > 0, 'Pipelined function sikeresen visszaadott sorokat.', 'A Pipelined function üres!');

    -- =========================================================================
    -- 3. JSON GENERÁLÁS (ty_user_stats)
    -- =========================================================================
    print_header('3. JSON OUTPUT GENERÁLÁS');
    
    SELECT user_id, name INTO v_user_id, v_user_name FROM users WHERE rownum = 1;
    DBMS_OUTPUT.PUT_LINE('Teszt alany: ' || v_user_name);
    
    BEGIN
        DBMS_OUTPUT.PUT_LINE('JSON Output:');
        DBMS_OUTPUT.PUT_LINE(pkg_user_management.get_user_stats_json(v_user_id));
        assert(TRUE, 'JSON generálás sikeres.', 'Hiba');
    EXCEPTION WHEN OTHERS THEN
        assert(FALSE, '', 'JSON generálás elszállt: ' || SQLERRM);
    END;

    -- =========================================================================
    -- 4. HIBAKEZELÉS ÉS NAPLÓZÁS (Negative Tests)
    -- =========================================================================
    print_header('4. HIBAKEZELÉS (PKG_EXCEPTION_HANDLER)');
    
    SELECT COUNT(*) INTO v_count_before FROM error_log;

    -- A) Duplikált Email
    DBMS_OUTPUT.PUT_LINE('Teszt A: Duplikált email beszúrása...');
    BEGIN
        pkg_user_management.add_user('Fake Admin', 'admin@lms.com', 'STUDENT'); -- admin@lms.com már létezik
        assert(FALSE, '', 'HIBA: Nem dobott kivételt duplikációra!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' -> Elkapott hiba: ' || SQLERRM);
        assert(SQLCODE = -20002 OR SQLCODE = -20000, 'Helyes hibakód elkapva.', 'Rossz hibakód érkezett.');
    END;

    -- B) Nem létező rekord törlése (Custom Exception)
    DBMS_OUTPUT.PUT_LINE('Teszt B: Nem létező lecke törlése...');
    BEGIN
        pkg_lesson_management.delete_lesson(999999);
        assert(FALSE, '', 'HIBA: Nem dobott kivételt nem létező ID-ra!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' -> Elkapott hiba: ' || SQLERRM);
        assert(SQLCODE = -20001, 'RECORD_NOT_FOUND (-20001) elkapva.', 'Rossz hibakód.');
    END;

    -- C) Üzleti szabály (Önkihívás)
    DBMS_OUTPUT.PUT_LINE('Teszt C: Önmaga elleni kihívás...');
    BEGIN
        pkg_challenge_system.create_challange(v_user_id, v_user_id, 200);
        assert(FALSE, '', 'HIBA: Nem dobott kivételt önkihívásra!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' -> Elkapott hiba: ' || SQLERRM);
        assert(SQLCODE = -20003, 'BUSINESS_RULE (-20003) elkapva.', 'Rossz hibakód.');
    END;

    -- Log ellenőrzés
    SELECT COUNT(*) INTO v_count_after FROM error_log;
    DBMS_OUTPUT.PUT_LINE('Log sorok száma előtte: ' || v_count_before || ', Utána: ' || v_count_after);
    assert(v_count_after > v_count_before, 'A rendszer automatikusan naplózta a hibákat.', 'A hibák nem kerültek be az error_log-ba!');

    -- =========================================================================
    -- 5. HISTORY ÉS TRIGGEREK
    -- =========================================================================
    print_header('5. AUDIT ÉS HISTORY TRIGGEREK');
    
    -- Elmentjük a jelenlegi állapotot
    SELECT COUNT(*) INTO v_count_before FROM users_h WHERE user_id = v_user_id;
    
    DBMS_OUTPUT.PUT_LINE('Felhasználó módosítása (Trigger aktiválás)...');
    UPDATE users SET name = v_user_name || ' (MOD)' WHERE user_id = v_user_id;
    COMMIT; -- Fontos, hogy a tranzakció lezáruljon
    
    SELECT COUNT(*) INTO v_count_after FROM users_h WHERE user_id = v_user_id;
    DBMS_OUTPUT.PUT_LINE('History sorok száma: ' || v_count_after);
    
    assert(v_count_after > v_count_before, 'A users_h táblába bekerült a módosítás.', 'A history trigger NEM működött!');

    -- Visszaállítás (hogy szép maradjon az adatbázis)
    UPDATE users SET name = v_user_name WHERE user_id = v_user_id;
    COMMIT;

    -- =========================================================================
    -- 6. KARBANTARTÓ JOB ÉS ADMIN TOOLS
    -- =========================================================================
    print_header('6. KARBANTARTÁS ÉS JOB');
    
    DBMS_OUTPUT.PUT_LINE('Kézi karbantartás indítása...');
    BEGIN
        pkg_admin_tools.daily_maintenance;
        assert(TRUE, 'A daily_maintenance lefutott hiba nélkül.', '');
    EXCEPTION WHEN OTHERS THEN
        assert(FALSE, '', 'A Job logikája hibára futott: ' || SQLERRM);
    END;
    
    -- Ellenőrizzük, hogy bekerült-e a logba a futás ténye (api mező alapján)
    SELECT COUNT(*) INTO v_count_after 
      FROM admin_logs
     WHERE action_type = 'SYSTEM_MAINTENANCE'; 
       
    assert(v_count_after > 0, 'A karbantartás sikeresen naplózta magát.', 'Nincs nyoma a karbantartásnak a logban.');

    -- =========================================================================
    -- 7. NÉZETEK (VIEWS) TESZTELÉSE
    -- =========================================================================
    print_header('7. NÉZETEK (VIEWS) ELLENŐRZÉSE');

    -- A) VW_LESSON_PERFORMANCE_REPORT
    DBMS_OUTPUT.PUT_LINE('[VIEW] vw_lesson_performance_report (Top 3):');
    FOR r IN (SELECT title, users_attempted, avg_score, best_score FROM vw_lesson_performance_report WHERE rownum <= 3) LOOP
        DBMS_OUTPUT.PUT_LINE(' - ' || r.title || ': Users=' || r.users_attempted || ', Avg=' || r.avg_score);
    end loop;

    -- B) VW_USER_PROGRESS_OVERVIEW
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '[VIEW] vw_user_progress_overview (Top 3):');
    FOR r IN (SELECT name, xp, completed_lessons, challenges_won FROM vw_user_progress_overview WHERE rownum <= 3) LOOP
        DBMS_OUTPUT.PUT_LINE(' - ' || r.name || ': XP=' || r.xp || ', Lessons=' || r.completed_lessons || ', Wins=' || r.challenges_won);
    end loop;

    -- C) VW_CLASSROOM_MEMBER_STATS
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '[VIEW] vw_classroom_member_stats (Top 3):');
    FOR r IN (SELECT classroom_name, member_name, completed_lessons FROM vw_classroom_member_stats WHERE rownum <= 3) LOOP
        DBMS_OUTPUT.PUT_LINE(' - [' || r.classroom_name || '] ' || r.member_name || ': Completed=' || r.completed_lessons);
    end loop;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== A TELJES RENDSZERTESZT BEFEJEZŐDÖTT ===');
END;
/
