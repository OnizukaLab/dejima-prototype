CREATE EXTENSION pgrowlocks;

CREATE TABLE BT (
	ID		INT PRIMARY KEY,
	COL1	VARCHAR(30),
	COL2	VARCHAR(30),
	COL3	VARCHAR(30)
);

\echo 'LOADING bt'
INSERT INTO bt VALUES
(1, 'abcde', 'abcde', 'abcde'),
(2, 'fghij', 'fghij', 'fghij'),
(3, 'klmno', 'klmno', 'klmno');

CREATE TABLE BT_LINEAGE (
		ID		INT PRIMARY KEY,
        LINEAGE VARCHAR(80)
	);

\echo 'LOADING bt_lineage'
INSERT INTO bt_lineage VALUES
(1,'<PeerA,bt,1>'),
(2,'<PeerA,bt,2>'),
(3,'<PeerA,bt,3>');