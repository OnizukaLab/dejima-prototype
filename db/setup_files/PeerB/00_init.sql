CREATE EXTENSION pgrowlocks;

CREATE TABLE BT (
	ID		INT PRIMARY KEY,
	COL1	VARCHAR(30),
	COL2	VARCHAR(30),
	COL3	VARCHAR(30)
);

\echo 'LOADING bt'
insert into bt (id, col1, col2, col3)
select
	i as id, 
	left(md5(i::text), 5) as col1,
	left(md5((i+1)::text), 5) as col2,
	left(md5((i+2)::text), 5) as col3 
from generate_series(1,10000) as i;

CREATE TABLE BT_LINEAGE (
		ID		INT PRIMARY KEY,
        LINEAGE VARCHAR(80)
	);

\echo 'LOADING bt_lineage'
INSERT INTO bt_lineage (id, lineage)
select i as id, '<PeerA,bt,' || i::text || '>' from generate_series(1,10000) as i;