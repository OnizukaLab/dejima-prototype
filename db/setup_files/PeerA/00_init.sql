CREATE EXTENSION pgrowlocks;

CREATE TABLE BT (
	ID		INT PRIMARY KEY,
	VID 	INT,
	LOCATION 	VARCHAR(30),
	RID 	INT
);

\echo 'LOADING bt'
insert into bt values (1, 1, 'Demachi', 1), (2, 2, 'Kyoto Station', 2), (3, 3, 'Shijo', 0);

CREATE TABLE BT_LINEAGE (
		ID		INT PRIMARY KEY,
        LINEAGE VARCHAR(80)
	);

\echo 'LOADING bt_lineage'
insert into bt_lineage values (1, '<peerA,bt,1>'), (2, '<peerA,bt,2>'), (3, '<peerA,bt,3>');