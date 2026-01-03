CREATE TABLE exercises_h AS SELECT * FROM exercises WHERE 1=0;

ALTER TABLE exercises_h ADD (
    hist_id      NUMBER(10),
    hist_action  CHAR(1),
    hist_user    VARCHAR2(50),
    hist_date    TIMESTAMP,
    version_no   NUMBER
);

ALTER TABLE exercises_h ADD CONSTRAINT pk_exercises_h PRIMARY KEY (hist_id);
CREATE SEQUENCE seq_exercises_h START WITH 1 INCREMENT BY 1;
