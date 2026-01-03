--- 1. FELHASZNÁLÓK ---
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_last_login ON users(last_login);
CREATE INDEX idx_users_xp ON users(xp);


 --- 2. PROGRESS ÉS EREDMÉNYEK  ---
CREATE INDEX idx_progress_lookup ON progress(user_id, lesson_id);
CREATE INDEX idx_results_user_fk ON results(user_id);
CREATE INDEX idx_results_lesson_fk ON results(lesson_id);


--- 3. KIHÍVÁSOK ---
CREATE INDEX idx_chall_participants ON challenges(challenger_id, opponent_id);
CREATE INDEX idx_chall_status ON challenges(status);


 --- 4. OSZTÁLYTERMEK  ---
CREATE INDEX idx_clmem_class_fk ON classroom_members(classroom_id);
CREATE INDEX idx_clmem_user_fk ON classroom_members(user_id);


 --- 5. NAPLÓK  ---
CREATE INDEX idx_errlog_maintenance ON error_log(err_time);
CREATE INDEX idx_adminlog_maintenance ON admin_logs(logged_at);


 --- 6. HISTORY TÁBLÁK  ---
CREATE INDEX idx_users_h_date ON users_h(hist_date);
CREATE INDEX idx_lessons_h_date ON lessons_h(hist_date);
