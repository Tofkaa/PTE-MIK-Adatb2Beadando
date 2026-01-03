CREATE OR REPLACE PACKAGE pkg_exception_handler IS

  -- ======================================================
  -- 1. SAJÁT KIVÉTELEK DEFINIÁLÁSA
  -- ======================================================
  e_record_not_found       EXCEPTION;
  e_duplicate_record       EXCEPTION;
  e_invalid_parameter      EXCEPTION;
  e_foreign_key_violation  EXCEPTION;
  e_business_rule_violated EXCEPTION;

  PRAGMA EXCEPTION_INIT(e_record_not_found, -20001);
  PRAGMA EXCEPTION_INIT(e_duplicate_record, -20002);
  PRAGMA EXCEPTION_INIT(e_business_rule_violated, -20003);
  PRAGMA EXCEPTION_INIT(e_invalid_parameter, -20004);
  PRAGMA EXCEPTION_INIT(e_foreign_key_violation, -2291);

  -- ======================================================
  -- 2. KÖZPONTI KEZELŐ ELJÁRÁSOK
  -- ======================================================

  PROCEDURE handle_custom_error(p_error_name IN VARCHAR2
                               ,p_message    IN VARCHAR2
                               ,p_context    IN VARCHAR2
                               ,p_api_name   IN VARCHAR2);

  PROCEDURE handle_system_error(p_sqlcode  IN NUMBER
                               ,p_sqlerrm  IN VARCHAR2
                               ,p_context  IN VARCHAR2
                               ,p_api_name IN VARCHAR2);

END pkg_exception_handler;
/
CREATE OR REPLACE PACKAGE BODY pkg_exception_handler IS

  PROCEDURE handle_custom_error(p_error_name IN VARCHAR2
                               ,p_message    IN VARCHAR2
                               ,p_context    IN VARCHAR2
                               ,p_api_name   IN VARCHAR2) IS
  BEGIN
    pkg_err_log.err_log(p_err_message => p_error_name || ': ' || p_message,
                        p_err_value   => p_context,
                        p_api         => p_api_name);
  
    IF p_error_name = 'RECORD_NOT_FOUND'
    THEN
      raise_application_error(-20001, 'Hiba: ' || p_message);
    ELSIF p_error_name = 'DUPLICATE_RECORD'
    THEN
      raise_application_error(-20002, 'Hiba: ' || p_message);
    ELSIF p_error_name = 'BUSINESS_RULE'
    THEN
      raise_application_error(-20003, 'Hiba: ' || p_message);
    ELSIF p_error_name = 'INVALID_PARAM'
    THEN
      raise_application_error(-20004, 'Hiba: ' || p_message);
    ELSE
      raise_application_error(-20000, 'Általános hiba: ' || p_message);
    END IF;
  END handle_custom_error;

  PROCEDURE handle_system_error(p_sqlcode  IN NUMBER
                               ,p_sqlerrm  IN VARCHAR2
                               ,p_context  IN VARCHAR2
                               ,p_api_name IN VARCHAR2) IS
  BEGIN
  
    IF p_sqlcode = -1
    THEN
      handle_custom_error('DUPLICATE_RECORD',
                          'Az adat már létezik a rendszerben.',
                          p_context,
                          p_api_name);
    
    ELSIF p_sqlcode = -2291
    THEN
      handle_custom_error('INVALID_PARAM',
                          'Érvénytelen hivatkozás (pl. nem létező ID).',
                          p_context,
                          p_api_name);
    
    ELSIF p_sqlcode BETWEEN - 20999 AND - 20000
    THEN
      raise_application_error(p_sqlcode, p_sqlerrm);
    
    ELSE
      pkg_err_log.err_log(p_err_message => 'SYSTEM ERROR: ' || p_sqlerrm,
                          p_err_value   => p_context || ' | Backtrace: ' ||
                                           dbms_utility.format_error_backtrace,
                          p_api         => p_api_name);
    
      raise_application_error(-20000,
                              'Váratlan rendszerhiba történt: ' ||
                              p_sqlerrm);
    END IF;
  END handle_system_error;

END pkg_exception_handler;
/
