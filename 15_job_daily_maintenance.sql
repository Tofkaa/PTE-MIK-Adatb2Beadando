BEGIN
  BEGIN
    DBMS_SCHEDULER.drop_job(job_name => 'JOB_DAILY_MAINTENANCE');
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;


  DBMS_SCHEDULER.create_job(
    job_name        => 'JOB_DAILY_MAINTENANCE',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'pkg_admin_tools.daily_maintenance',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=0; BYSECOND=0', 
    enabled         => TRUE,
    comments        => 'Napi karbantartás: logok törlése, inaktív userek szűrése'
  );
  
  DBMS_OUTPUT.PUT_LINE('Napi karbantartó Job sikeresen létrehozva és időzítve.');
END;
/
