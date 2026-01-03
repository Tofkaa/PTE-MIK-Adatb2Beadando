CREATE OR REPLACE VIEW vw_classroom_member_stats AS
SELECT 
    c.classroom_id,
    c.name AS classroom_name,
    c.description AS classroom_description,
    t.name AS teacher_name,
    cm.user_id AS member_id,
    u.name AS member_name,
    cm.joined_at,


    (SELECT COUNT(*)
       FROM progress p
      WHERE p.user_id = cm.user_id
    ) AS total_lessons_attempted,


    (SELECT COUNT(*)
       FROM progress p
      WHERE p.user_id = cm.user_id
        AND p.is_completed = 'Y'
    ) AS completed_lessons,


    (SELECT NVL(AVG(r.score), 0)
       FROM results r
      WHERE r.user_id = cm.user_id
    ) AS average_score,


    GREATEST(
        NVL((SELECT MAX(p2.last_attempt_at)
               FROM progress p2
              WHERE p2.user_id = cm.user_id),
            TO_TIMESTAMP('1900-01-01','YYYY-MM-DD')),
        NVL((SELECT MAX(r2.submitted_at)
               FROM results r2
              WHERE r2.user_id = cm.user_id),
            TO_TIMESTAMP('1900-01-01','YYYY-MM-DD'))
    ) AS last_activity,


    u.xp AS current_xp

FROM classrooms c
JOIN classroom_members cm 
  ON c.classroom_id = cm.classroom_id
JOIN users u 
  ON cm.user_id = u.user_id
LEFT JOIN users t 
  ON c.teacher_id = t.user_id;
