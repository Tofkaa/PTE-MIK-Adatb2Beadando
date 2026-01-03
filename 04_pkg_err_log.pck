CREATE OR REPLACE PACKAGE pkg_err_log IS

  PROCEDURE err_log(p_err_message VARCHAR2
                   ,p_err_value   VARCHAR2
                   ,p_api         VARCHAR2);

END pkg_err_log;
/
CREATE OR REPLACE PACKAGE BODY pkg_err_log IS

  PROCEDURE err_log(p_err_message VARCHAR2
                   ,p_err_value   VARCHAR2
                   ,p_api         VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO error_log
      (err_id
      ,err_message
      ,err_value
      ,api)
    VALUES
      (error_log_seq.nextval
      ,p_err_message
      ,p_err_value
      ,p_api);
  
    COMMIT;
  END err_log;

END pkg_err_log;
/
