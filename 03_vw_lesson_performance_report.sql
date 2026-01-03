CREATE OR REPLACE VIEW vw_lesson_performance_report AS
SELECT 
    l.lesson_id,
    l.title,
    l.difficulty,
    l.language,
    lt.name AS topic_name,


    (SELECT COUNT(DISTINCT p.user_id)
       FROM progress p
      WHERE p.lesson_id = l.lesson_id
    ) AS users_attempted,


    (SELECT COUNT(DISTINCT p.user_id)
       FROM progress p
      WHERE p.lesson_id = l.lesson_id
        AND p.is_completed = 'Y'
    ) AS users_completed,


    (SELECT COUNT(*)
       FROM results r
      WHERE r.lesson_id = l.lesson_id
    ) AS total_results_submitted,


    (SELECT NVL(AVG(r.score), 0)
       FROM results r
      WHERE r.lesson_id = l.lesson_id
    ) AS avg_score,


    (SELECT NVL(AVG(r.time_taken), 0)
       FROM results r
      WHERE r.lesson_id = l.lesson_id
    ) AS avg_time_taken,


    (SELECT NVL(MAX(r.score), 0)
       FROM results r
      WHERE r.lesson_id = l.lesson_id
    ) AS best_score,


    (SELECT COUNT(*)
       FROM challenges c
      WHERE c.lesson_id = l.lesson_id
    ) AS challenge_usage_count,


    (SELECT MAX(p.last_attempt_at)
       FROM progress p
      WHERE p.lesson_id = l.lesson_id
    ) AS last_attempt

FROM lessons l
LEFT JOIN lesson_topics lt
       ON l.topic_id = lt.topic_id;
