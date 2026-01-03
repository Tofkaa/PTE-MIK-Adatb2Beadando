CREATE TABLE achievements_h AS SELECT * FROM achievements WHERE 1=0;

ALTER TABLE achievements_h ADD (
    hist_id      NUMBER(10),
    hist_action  CHAR(1),
    hist_user    VARCHAR2(50),
    hist_date    TIMESTAMP,
    version_no   NUMBER
);

ALTER TABLE achievements_h ADD CONSTRAINT pk_achievements_h PRIMARY KEY (hist_id);
CREATE SEQUENCE seq_achievements_h START WITH 1 INCREMENT BY 1;
