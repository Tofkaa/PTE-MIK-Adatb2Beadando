CREATE TABLE users_h AS SELECT * FROM users WHERE 1=0;

ALTER TABLE users_h ADD (
    hist_id      NUMBER(10),
    hist_action  CHAR(1),
    hist_user    VARCHAR2(255),
    hist_date    TIMESTAMP,
    version_no   NUMBER
);

ALTER TABLE users_h ADD CONSTRAINT pk_users_h primary key (hist_id);
create sequence seq_users_h start with 1 increment by 1;
