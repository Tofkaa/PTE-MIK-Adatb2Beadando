-- ======================================================
-- adatb2 proj F94IKY 
-- ======================================================
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*)
    INTO v_count
    FROM dba_users t
   WHERE t.username = 'NYELV_MANAGER1';
  IF v_count = 1
  THEN
    EXECUTE IMMEDIATE 'DROP USER nyelv_manager1 CASCADE';
  END IF;
END;

/

CREATE USER nyelv_manager1 identified BY "nyelv123" DEFAULT tablespace users quota unlimited ON users;

grant CREATE session TO nyelv_manager1;
grant CREATE TABLE TO nyelv_manager1;
grant CREATE view TO nyelv_manager1;
grant CREATE sequence TO nyelv_manager1;
grant CREATE PROCEDURE TO nyelv_manager1;
grant CREATE TYPE TO nyelv_manager1;
grant CREATE TRIGGER TO nyelv_manager1;
grant CREATE JOB to nyelv_manager1;

ALTER session SET current_schema = nyelv_manager1;

-- ======================================================
-- NYELV_MANAGER SCHEMA INIT SCRIPT
-- ======================================================


---------------------------------------------------------
-- MAIN SEQUENCES
---------------------------------------------------------
CREATE sequence seq_lesson_topics START
  WITH 100 increment BY 1 nocache nocycle;
CREATE sequence seq_lessons START
  WITH 200 increment BY 1 nocache nocycle;
CREATE sequence seq_exercises START
  WITH 300 increment BY 1 nocache nocycle;
CREATE sequence seq_classrooms START
  WITH 400 increment BY 1 nocache nocycle;
CREATE sequence seq_classroom_members START
  WITH 500 increment BY 1 nocache nocycle;
CREATE sequence seq_achievements START
  WITH 600 increment BY 1 nocache nocycle;
CREATE sequence seq_user_achievements START
  WITH 700 increment BY 1 nocache nocycle;
CREATE sequence seq_progress START
  WITH 800 increment BY 1 nocache nocycle;
CREATE sequence seq_results START
  WITH 900 increment BY 1 nocache nocycle;
CREATE sequence seq_admin_logs START
  WITH 1000 increment BY 1 nocache nocycle;
CREATE sequence error_log_seq START
  WITH 1 increment BY 1 nocache nocycle;

---------------------------------------------------------
-- USERS
---------------------------------------------------------
CREATE TABLE users(user_id             RAW(16) DEFAULT sys_guid() primary key,
                   NAME VARCHAR2(255),
                   email VARCHAR2(255) UNIQUE NOT NULL,
                   password_hash VARCHAR2(255) NOT NULL,
                   role VARCHAR2(50),
                   xp                  NUMBER DEFAULT 0,
                   streak              NUMBER DEFAULT 0,
                   created_at          TIMESTAMP DEFAULT systimestamp,
                   last_login TIMESTAMP,
                   profile_picture_url VARCHAR2(500),
                   preferred_language VARCHAR2(20));

---------------------------------------------------------
-- LESSON_TOPICS
---------------------------------------------------------
CREATE TABLE lesson_topics(topic_id NUMBER primary key,
                           NAME VARCHAR2(255),
                           description VARCHAR2(4000));

---------------------------------------------------------
-- LESSONS
---------------------------------------------------------
CREATE TABLE lessons(lesson_id NUMBER primary key,
                     topic_id NUMBER,
                     title VARCHAR2(255) NOT NULL,
                     difficulty VARCHAR2(10),
                     LANGUAGE VARCHAR2(50),
                     description VARCHAR2(4000),
                     CONSTRAINT fk_lessons_topic foreign key(topic_id)
                     references lesson_topics(topic_id) ON DELETE SET NULL);

---------------------------------------------------------
-- EXERCISES
---------------------------------------------------------
CREATE TABLE exercises(exercise_id NUMBER primary key,
                       lesson_id NUMBER NOT NULL,
                       TYPE VARCHAR2(50),
                       content VARCHAR2(4000),
                       correct_answer VARCHAR2(4000),
                       audio_url VARCHAR2(500),
                       image_url VARCHAR2(500),
                       CONSTRAINT fk_exercise_lesson foreign key(lesson_id)
                       references lessons(lesson_id) ON DELETE cascade
                       -- Ha törlöm a leckét, a feladatok is törlődjenek!
                       );

---------------------------------------------------------
-- PROGRESS
---------------------------------------------------------
CREATE TABLE progress(progress_id     RAW(16) DEFAULT sys_guid() primary key,
                      user_id RAW(16) NOT NULL,
                      lesson_id NUMBER NOT NULL,
                      completed_at TIMESTAMP,
                      highest_score NUMBER,
                      last_attempt_at TIMESTAMP,
                      is_completed CHAR(1)
                      CHECK(is_completed IN ('Y', 'N')),
                      
                      CONSTRAINT fk_progress_user foreign key(user_id)
                      references users(user_id) ON DELETE cascade,
                      -- Ha a user törlődik, a hozzá tartozó progress is törlődjön
                      
                      CONSTRAINT fk_progress_lesson foreign key(lesson_id)
                      references lessons(lesson_id) ON DELETE cascade);

---------------------------------------------------------
-- RESULTS
---------------------------------------------------------
CREATE TABLE results(result_id             RAW(16) DEFAULT sys_guid()
                                                           primary key,
                     user_id RAW(16) NOT NULL,
                     lesson_id NUMBER NOT NULL,
                     score NUMBER,
                     time_taken NUMBER,
                     submitted_at TIMESTAMP,
                     is_challenge_result CHAR(1)
                     CHECK(is_challenge_result IN ('Y', 'N')),
                     challenge_id RAW(16),
                     is_test_result CHAR(1)
                     CHECK(is_test_result IN ('Y', 'N')),
                     correct_answers_count NUMBER,
                     total_questions_count NUMBER,
                     
                     CONSTRAINT fk_result_user foreign key(user_id)
                     references users(user_id) ON DELETE cascade,
                     --User törlésnél az eredményei is törlődjenek
                     
                     CONSTRAINT fk_result_lesson foreign key(lesson_id)
                     references lessons(lesson_id) ON DELETE cascade);

---------------------------------------------------------
-- CLASSROOMS
---------------------------------------------------------
CREATE TABLE classrooms(classroom_id NUMBER primary key,
                        NAME VARCHAR2(255) NOT NULL,
                        description VARCHAR2(4000),
                        teacher_id RAW(16),
                        invite_code VARCHAR2(50) UNIQUE,
                        created_at   TIMESTAMP DEFAULT systimestamp,
                        
                        CONSTRAINT fk_classroom_teacher foreign
                        key(teacher_id) references users(user_id) ON DELETE SET NULL
                        --Ha a tanárt törlik, az osztály megmarad, csak "gazdátlan" lesz.
                        );

---------------------------------------------------------
-- CLASSROOM_MEMBERS
---------------------------------------------------------
CREATE TABLE classroom_members(classroom_member_id NUMBER primary key,
                               classroom_id NUMBER NOT NULL,
                               user_id RAW(16) NOT NULL,
                               joined_at           TIMESTAMP DEFAULT systimestamp,
                               
                               CONSTRAINT fk_clmember_class foreign
                               key(classroom_id) references
                               classrooms(classroom_id) ON DELETE cascade,
                               -- Ha az osztály megszűnik, a tagság is szűnjön meg.
                               
                               CONSTRAINT fk_clmember_user foreign
                               key(user_id) references users(user_id) ON
                               DELETE cascade
                               -- User törlésnél törlődik a tagság.
                               );

---------------------------------------------------------
-- CHALLENGES
---------------------------------------------------------
CREATE TABLE challenges(challenge_id  RAW(16) DEFAULT sys_guid() primary key,
                        challenger_id RAW(16) NOT NULL,
                        opponent_id RAW(16) NOT NULL,
                        lesson_id NUMBER NOT NULL,
                        winner_id RAW(16),
                        start_time TIMESTAMP,
                        end_time TIMESTAMP,
                        status VARCHAR2(50),
                        
                        CONSTRAINT fk_challenge_challenger foreign
                        key(challenger_id) references users(user_id) ON
                        DELETE cascade,
                        
                        CONSTRAINT fk_challenge_opponent foreign
                        key(opponent_id) references users(user_id) ON
                        DELETE cascade,
                        -- Bármelyik fél törlésekor a kihívás is törlődik.
                        
                        CONSTRAINT fk_challenge_winner foreign
                        key(winner_id) references users(user_id) ON DELETE SET NULL,
                        
                        CONSTRAINT fk_challenge_lesson foreign
                        key(lesson_id) references lessons(lesson_id) ON
                        DELETE cascade);

---------------------------------------------------------
-- ACHIEVEMENTS
---------------------------------------------------------
CREATE TABLE achievements(achievement_id NUMBER primary key,
                          NAME VARCHAR2(255) UNIQUE NOT NULL,
                          description VARCHAR2(4000),
                          criteria VARCHAR2(500),
                          icon_url VARCHAR2(500));

---------------------------------------------------------
-- USER_ACHIEVEMENTS
---------------------------------------------------------
CREATE TABLE user_achievements(user_achievement_id NUMBER primary key,
                               user_id RAW(16) NOT NULL,
                               achievement_id NUMBER NOT NULL,
                               achieved_at         TIMESTAMP DEFAULT systimestamp,
                               
                               CONSTRAINT fk_userach_user foreign
                               key(user_id) references users(user_id) ON
                               DELETE cascade,
                               -- User törlésnél az achievementjei is törlődnek.
                               
                               CONSTRAINT fk_userach_ach foreign
                               key(achievement_id) references
                               achievements(achievement_id) ON DELETE
                               cascade);

---------------------------------------------------------
-- ADMIN_LOGS
---------------------------------------------------------
CREATE TABLE admin_logs(log_id              RAW(16) DEFAULT sys_guid()
                                                            primary key,
                        admin_id RAW(16),
                        action_type VARCHAR2(100),
                        target_user_id RAW(16),
                        target_classroom_id NUMBER,
                        details VARCHAR2(4000),
                        logged_at           TIMESTAMP DEFAULT systimestamp,
                        
                        CONSTRAINT fk_log_admin foreign key(admin_id)
                        references users(user_id) ON DELETE SET NULL,
                        --Ha törlünk egy admint, a log maradjon meg az audit miatt, csak a név tűnik el.
                        
                        CONSTRAINT fk_log_target_user foreign
                        key(target_user_id) references users(user_id) ON
                        DELETE SET NULL,
                        --Ha a célpont user törlődik, a log maradjon meg.
                        
                        CONSTRAINT fk_log_target_class foreign
                        key(target_classroom_id) references
                        classrooms(classroom_id) ON DELETE SET NULL);

---------------------------------------------------------
-- ERROR_LOG
---------------------------------------------------------                    
CREATE TABLE error_log(err_id NUMBER,
                       err_time    TIMESTAMP DEFAULT SYSDATE,
                       err_message VARCHAR2(4000),
                       err_value VARCHAR2(4000),
                       api VARCHAR2(100));
