CREATE TABLE student (
  ID int NOT NULL,
  UNIVERSITY varchar(80) NOT NULL,
  FIRST_NAME varchar(80),
  LAST_NAME varchar(80),
  PRIMARY KEY(ID, UNIVERSITY),
  CONSTRAINT university_check CHECK(UNIVERSITY = 'Osaka' OR UNIVERSITY = 'Hosei')
);