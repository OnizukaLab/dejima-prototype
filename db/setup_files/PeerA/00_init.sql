CREATE EXTENSION pgrowlocks;

CREATE TABLE BT (
	DEJIMA_ID		INT PRIMARY KEY,
	VID 	INT,
	LOCATION 	VARCHAR(30),
	RID 	INT
);

\echo 'LOADING bt'
insert into bt values (1, 1, 'Demachi', 1), (2, 2, 'Kyoto Station', 2), (3, 3, 'Shijo', 0);