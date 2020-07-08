CREATE TABLE student (
  ID int,
  FIRST_NAME varchar(80) NOT NULL,
  LAST_NAME varchar(80),
  UNIVERSITY varchar(80) NOT NULL,
  unique(ID, UNIVERSITY)
);