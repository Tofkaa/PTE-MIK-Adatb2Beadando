CREATE TABLE lessons_h AS SELECT * FROM lessons where 1=0;

ALTER TABLE lessons_h ADD (
    hist_id      NUMBER(10),
    hist_action  CHAR(1),
    hist_user    VARCHAR2(50),
    hist_date    TIMESTAMP,
    version_no   NUMBER
);

ALTER TABLE lessons_h ADD CONSTRAINT pk_lessons_h PRIMARY KEY (hist_id);
CREATE SEQUENCE seq_lessons_h START WITH 1 INCREMENT BY 1;
