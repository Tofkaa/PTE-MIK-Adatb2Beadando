---------------------------------------------------------
-- TYPE: ty_lesson_performance
---------------------------------------------------------
CREATE OR REPLACE TYPE ty_lesson_performance AS OBJECT (
    lesson_id        NUMBER,
    lesson_title     VARCHAR2(255),
    avg_score        NUMBER,
    attempt_count    NUMBER,
    completion_rate  NUMBER
);

/

---------------------------------------------------------
-- TYPE: ty_lesson_performance_tab
---------------------------------------------------------
CREATE OR REPLACE TYPE ty_lesson_performance_tab
  AS TABLE OF ty_lesson_performance;

/

---------------------------------------------------------
-- TYPE: ty_user_stats
---------------------------------------------------------
CREATE OR REPLACE TYPE ty_user_stats AS OBJECT (
    user_id               RAW(16),
    user_name             VARCHAR2(255),
    total_lessons_done    NUMBER,
    avg_score             NUMBER,
    total_xp              NUMBER,
    achievements_count    NUMBER,
    challenge_wins        NUMBER,
    challenge_losses      NUMBER,
    streak                NUMBER
);

/

---------------------------------------------------------
-- TYPE: ty_user_stats_tab
---------------------------------------------------------
CREATE OR REPLACE TYPE ty_user_stats_tab
  AS TABLE OF ty_user_stats;
