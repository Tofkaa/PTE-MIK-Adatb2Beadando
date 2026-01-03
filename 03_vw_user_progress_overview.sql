CREATE OR REPLACE VIEW vw_user_progress_overview AS 
SELECT 
    u.user_id,
    u.name,
    u.email,
    u.role,
    u.xp,
    u.streak,


    (SELECT COUNT(*)
       FROM progress p
      WHERE p.user_id = u.user_id
        AND p.is_completed = 'Y'
    ) AS completed_lessons,


    (SELECT NVL(AVG(r.score), 0)
       FROM results r
      WHERE r.user_id = u.user_id
    ) AS average_score,


    GREATEST(
        NVL((SELECT MAX(p2.last_attempt_at)
               FROM progress p2
              WHERE p2.user_id = u.user_id), TO_TIMESTAMP('1900-01-01','YYYY-MM-DD')),
        NVL((SELECT MAX(r2.submitted_at)
               FROM results r2
              WHERE r2.user_id = u.user_id), TO_TIMESTAMP('1900-01-01','YYYY-MM-DD'))
    ) AS last_activity,


    (SELECT COUNT(*)
       FROM challenges c
      WHERE c.winner_id = u.user_id
    ) AS challenges_won

FROM users u
ORDER BY u.xp DESC, u.name ASC; 
