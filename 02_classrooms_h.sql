CREATE TABLE classrooms_h AS SELECT * FROM classrooms WHERE 1=0;

ALTER TABLE classrooms_h ADD (
    hist_id      NUMBER(10),
    hist_action  CHAR(1),
    hist_user    VARCHAR2(50),
    hist_date    TIMESTAMP,
    version_no   NUMBER
);

ALTER TABLE classrooms_h ADD CONSTRAINT pk_classrooms_h PRIMARY KEY (hist_id);
CREATE SEQUENCE seq_classrooms_h START WITH 1 INCREMENT BY 1;
