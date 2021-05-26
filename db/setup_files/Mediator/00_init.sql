CREATE EXTENSION pgrowlocks;

CREATE TABLE BT (
	DEJIMA_ID		INT PRIMARY KEY,
	VID 	INT,
	LOCATION 	VARCHAR(30),
	RID 	INT,
	PROVIDER	VARCHAR(30)
);

\echo 'LOADING bt'
insert into bt values (1, 1, 'Demachi', 1, 'A'), (2, 2, 'Kyoto Station', 2, 'A'), (3, 3, 'Shijo', 0, 'A'), (4, 4, 'Demachi', 0, 'C'), (5, 5, 'Gion', 3, 'C');