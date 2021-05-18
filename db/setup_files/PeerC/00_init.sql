CREATE EXTENSION pgrowlocks;

CREATE TABLE BT (
	ID		INT PRIMARY KEY,
	VID 	INT,
	LOCATION 	VARCHAR(30),
	RID 	INT,
	SHARABLE	VARCHAR(80)
);

\echo 'LOADING bt'
insert into bt values (4, 4, 'Demachi', 0, 'True'), (5, 5, 'Gion', 3, 'True'), (6, 6, 'Kitayama', 0, 'False');

CREATE TABLE BT_LINEAGE (
		ID		INT PRIMARY KEY,
        LINEAGE VARCHAR(80)
	);

\echo 'LOADING bt_lineage'
insert into bt_lineage values (4, '<peerC,bt,4>'), (5, '<peerC,bt,5>'), (6, '<peerC,bt,6>');