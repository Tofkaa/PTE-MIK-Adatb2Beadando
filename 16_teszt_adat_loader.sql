

DECLARE
    -- ID Tárolók a dinamikus hivatkozáshoz
    TYPE t_id_list IS TABLE OF RAW(16) INDEX BY PLS_INTEGER;
    v_students      t_id_list;
    v_teachers      t_id_list;
    v_admin_id      RAW(16);
    
    -- Témakörök
    v_topic_a1_id   NUMBER;
    v_topic_b2_id   NUMBER;
    
    -- Leckék
    v_lesson_present_id NUMBER; -- Present Simple
    v_lesson_past_id    NUMBER; -- Past Simple (ÚJ)
    v_lesson_email_id   NUMBER; -- Email Writing
    v_lesson_neg_id     NUMBER; -- Negotiation (ÚJ)
    
    -- Egyéb
    v_class_id      NUMBER;
    v_ach_id        NUMBER;
    v_random_score  NUMBER;
    v_chall_id      RAW(16);

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== ADAT BETÖLTÉS INDÍTÁSA ===');

    -- =================================================================
    -- 1. FELHASZNÁLÓK (1 Admin, 2 Tanár, 15 Diák)
    -- =================================================================
    DBMS_OUTPUT.PUT_LINE('>> 1. Felhasználók generálása...');

    -- Admin
    pkg_user_management.add_user('Super Admin', 'admin@lms.com', 'ADMIN', NULL, 'HU');
    SELECT user_id INTO v_admin_id FROM users WHERE email = 'admin@lms.com';

    -- Tanárok
    pkg_user_management.add_user('Kovács Tanár', 'kovacs@lms.com', 'TEACHER', NULL, 'HU');
    SELECT user_id INTO v_teachers(1) FROM users WHERE email = 'kovacs@lms.com';
    
    pkg_user_management.add_user('Mrs. English', 'english@lms.com', 'TEACHER', NULL, 'EN');
    SELECT user_id INTO v_teachers(2) FROM users WHERE email = 'english@lms.com';

    -- Diákok (15 db)
    FOR i IN 1..15 LOOP
        pkg_user_management.add_user('Diák ' || i, 'student'||i||'@lms.com', 'STUDENT', NULL, CASE WHEN MOD(i,2)=0 THEN 'EN' ELSE 'HU' END);
        SELECT user_id INTO v_students(i) FROM users WHERE email = 'student'||i||'@lms.com';
        
        -- XP
        pkg_progress_tracking.add_xp(v_students(i), round(dbms_random.value(10, 100))); 
    END LOOP;

    -- =================================================================
    -- 2. TANANYAG (2 Téma, 4 Lecke, Sok Feladat)
    -- =================================================================
    DBMS_OUTPUT.PUT_LINE('>> 2. Tananyag bővítése...');

    -- TÉMA A: ANGOL ALAPOK (A1)
    pkg_lesson_management.create_lesson_topic('Angol Alapok A1', 'A nyelvtanulás alapkövei.');
    SELECT MAX(topic_id) INTO v_topic_a1_id FROM lesson_topics;

        -- Lecke A1: Present Simple
        pkg_lesson_management.create_lesson('Present Simple', 'EASY', 'EN', 'Jelen idő használata', v_topic_a1_id);
        SELECT lesson_id INTO v_lesson_present_id FROM lessons WHERE title = 'Present Simple' AND topic_id = v_topic_a1_id;
        
        pkg_lesson_management.create_exercise(v_lesson_present_id, 'FILL_IN', 'I ___ (to be) happy.', 'am', NULL, NULL);
        pkg_lesson_management.create_exercise(v_lesson_present_id, 'MULTIPLE_CHOICE', 'She ___ every day.', 'runs', NULL, NULL);
        pkg_lesson_management.create_exercise(v_lesson_present_id, 'FILL_IN', 'They ___ (not/like) pizza.', 'do not like', NULL, NULL);

        -- Lecke A2: Past Simple (ÚJ)
        pkg_lesson_management.create_lesson('Past Simple', 'MEDIUM', 'EN', 'Múlt idő eseményei', v_topic_a1_id);
        SELECT lesson_id INTO v_lesson_past_id FROM lessons WHERE title = 'Past Simple' AND topic_id = v_topic_a1_id;
        
        pkg_lesson_management.create_exercise(v_lesson_past_id, 'FILL_IN', 'Yesterday I ___ (go) home.', 'went', NULL, NULL);
        pkg_lesson_management.create_exercise(v_lesson_past_id, 'MULTIPLE_CHOICE', 'Did you ___ him?', 'see', NULL, NULL);

    -- TÉMA B: BUSINESS ENGLISH (B2)
    pkg_lesson_management.create_lesson_topic('Business English B2', 'Üzleti kommunikáció.');
    SELECT MAX(topic_id) INTO v_topic_b2_id FROM lesson_topics;
    
        -- Lecke B1: Email Writing
        pkg_lesson_management.create_lesson('Email Writing', 'HARD', 'EN', 'Hivatalos levelek', v_topic_b2_id);
        SELECT lesson_id INTO v_lesson_email_id FROM lessons WHERE title = 'Email Writing' AND topic_id = v_topic_b2_id;
        
        pkg_lesson_management.create_exercise(v_lesson_email_id, 'FILL_IN', 'Dear Sir or ___', 'Madam', NULL, NULL);
        pkg_lesson_management.create_exercise(v_lesson_email_id, 'MULTIPLE_CHOICE', 'Best ___', 'Regards', NULL, NULL);

        -- Lecke B2: Negotiation (ÚJ)
        pkg_lesson_management.create_lesson('Negotiation Skills', 'HARD', 'EN', 'Tárgyalási technikák', v_topic_b2_id);
        SELECT lesson_id INTO v_lesson_neg_id FROM lessons WHERE title = 'Negotiation Skills' AND topic_id = v_topic_b2_id;
        
        pkg_lesson_management.create_exercise(v_lesson_neg_id, 'MULTIPLE_CHOICE', 'Lets make a ___', 'deal', NULL, NULL);

    -- =================================================================
    -- 3. EREDMÉNYEK GENERÁLÁSA (Javítva: Nevesített paraméterátadás!)
    -- =================================================================
    DBMS_OUTPUT.PUT_LINE('>> 3. Eredmények és Progress...');

    FOR i IN 1..15 LOOP
        -- 1. Lecke
        v_random_score := TRUNC(dbms_random.value(40, 99));
        IF i = 1 THEN v_random_score := 100; END IF; -- Diák 1: Garantált 100%
        
        -- JAVÍTOTT HÍVÁS (nyíllal):
        pkg_progress_tracking.record_result(
            p_user_id         => v_students(i), 
            p_lesson_id       => v_lesson_present_id, 
            p_score           => v_random_score, 
            p_time_taken      => 120, 
            p_correct_answers => 8, 
            p_total_questions => 10
        );

        -- 2. Lecke (csak párosok)
        IF MOD(i, 2) = 0 THEN
             pkg_progress_tracking.record_result(
                p_user_id         => v_students(i), 
                p_lesson_id       => v_lesson_past_id, 
                p_score           => TRUNC(dbms_random.value(60, 90)), 
                p_time_taken      => 200, 
                p_correct_answers => 7, 
                p_total_questions => 10
            );
        END IF;

        -- 3. Lecke (csak legjobbak)
        IF i <= 5 THEN
             pkg_progress_tracking.record_result(
                p_user_id         => v_students(i), 
                p_lesson_id       => v_lesson_email_id, 
                p_score           => TRUNC(dbms_random.value(70, 100)), 
                p_time_taken      => 300, 
                p_correct_answers => 9, 
                p_total_questions => 10
            );
        END IF;
    END LOOP;

    -- =================================================================
    -- 4. OSZTÁLYOK ÉS KIHÍVÁSOK
    -- =================================================================
    DBMS_OUTPUT.PUT_LINE('>> 4. Közösségi funkciók...');

    -- Osztály
    pkg_classroom_management.create_classroom('Intenzív Angol', 'Haladó csoport', v_teachers(1), 'ADV2025');
    SELECT MAX(classroom_id) INTO v_class_id FROM classrooms;
    
    -- Tagok
    FOR i IN 1..5 LOOP
        pkg_classroom_management.add_member_to_classroom(v_class_id, v_students(i));
    END LOOP;

    -- Kihívások
    pkg_challenge_system.create_challange(v_students(1), v_students(2), v_lesson_present_id);
    
    -- Challenge ID megszerzése (korrigált lekérdezés)
    SELECT challenge_id INTO v_chall_id 
      FROM (SELECT challenge_id FROM challenges WHERE challenger_id = v_students(1) ORDER BY start_time DESC) 
     WHERE rownum = 1;
     
    pkg_challenge_system.complete_challange(v_chall_id, v_students(1)); -- D1 nyer

    pkg_challenge_system.create_challange(v_students(3), v_students(4), v_lesson_past_id);

    -- =================================================================
    -- 5. ACHIEVEMENTS ÉS ADMIN
    -- =================================================================
    DBMS_OUTPUT.PUT_LINE('>> 5. Admin és Achievementek...');

    -- Achievement
    pkg_achievements.create_achievement('Éltanuló', '100%-os lecke teljesítése', 'SCORE_100', 'star_badge.png');
    SELECT MAX(achievement_id) INTO v_ach_id FROM achievements;

    -- Kiosztás
    FOR r IN (SELECT DISTINCT user_id FROM results WHERE score = 100) LOOP
        pkg_achievements.grant_achievement(r.user_id, v_ach_id);
    END LOOP;

    -- Admin
    pkg_admin_tools.suspend_user(v_admin_id, v_students(15), 'Régóta inaktív.');

    DBMS_OUTPUT.PUT_LINE('=== ADATBETÖLTÉS KÉSZ ===');
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('!!! HIBA TÖRTÉNT: ' || SQLERRM);
        ROLLBACK;
END;
/
