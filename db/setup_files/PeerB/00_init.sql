CREATE EXTENSION pgrowlocks;

CREATE TABLE BT (
	DEJIMA_ID		INT PRIMARY KEY,
	VID 	INT,
	LOCATION 	VARCHAR(30),
	RID 	INT,
	SHARABLE	VARCHAR(80)
);

\echo 'LOADING bt'
insert into bt values (4, 4, 'Demachi', 0, 'True'), (5, 5, 'Gion', 3, 'True'), (6, 6, 'Kitayama', 0, 'False');