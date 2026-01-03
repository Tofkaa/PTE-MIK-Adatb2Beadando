 --- ADATOK TORLESE (TISZTA LAP) ---

BEGIN
  -- 1. LIVE TÁBLÁK TÖRLÉSE (Gyerekektől a szülők felé)
  
  -- Azokat töröljük először, amik másokra hivatkoznak
  DELETE FROM admin_logs;         -- FK: users, classrooms
  delete from error_log;
 -- DELETE FROM messages;           -- FK: users
  DELETE FROM user_achievements;  -- FK: users, achievements
  DELETE FROM classroom_members;  -- FK: users, classrooms
  
  DELETE FROM results;            -- FK: users, lessons, challenges
  DELETE FROM progress;           -- FK: users, lessons
  
  DELETE FROM challenges;         -- FK: users, lessons (Csak a results után!)
  DELETE FROM exercises;          -- FK: lessons
  
  -- Köztes szülők törlése
  DELETE FROM classrooms;         -- FK: users (teacher)
  DELETE FROM lessons;            -- FK: lesson_topics
  
  -- Független config táblák
  DELETE FROM lesson_topics;
  DELETE FROM achievements;
  
  -- A legfőbb szülő törlése
  DELETE FROM users;

  -- 2. HISTORY TÁBLÁK TÖRLÉSE
  -- Fontos: Ezeket a végén töröljük, mert a fenti DELETE parancsok
  -- aktiválhatják a triggereket, amik újraírnák a history-t!
  DELETE FROM achievements_h;
  DELETE FROM classrooms_h;
  DELETE FROM exercises_h;
  DELETE FROM lessons_h;
  DELETE FROM users_h;

  -- 3. VÉGLEGESÍTÉS
  COMMIT;
  
  DBMS_OUTPUT.PUT_LINE('Sikeresen törölve minden adat (Live + History).');

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Hiba történt a törlés közben: ' || SQLERRM);
END;
/
