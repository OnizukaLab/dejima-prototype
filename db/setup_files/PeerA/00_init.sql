CREATE EXTENSION pgrowlocks;

CREATE TABLE NATION (
	KEY		SERIAL,
	NAME	CHAR(25),
	DESCRIPTION		VARCHAR(152)
);

CREATE TABLE CUSTOMER (
	KEY		SERIAL,
	NAME	VARCHAR(25),
	ADDRESS		VARCHAR(40),
	PHONE	CHAR(15),
	NATIONKEY	BIGINT NOT NULL
);

ALTER TABLE CUSTOMER ADD PRIMARY KEY (KEY);
ALTER TABLE NATION ADD PRIMARY KEY (KEY);

\echo 'LOADING nation'
INSERT INTO nation VALUES
(1,'Japan','none'),
(2,'China','none'),
(3,'Vietnam','none');
\echo 'LOADING customer'
INSERT INTO customer VALUES 
(1,'A','Tokyo','2432',1),
(2,'B','Hanoi','5435',3),
(3,'C','Beijing','6524',2);

CREATE TABLE NATION_LINEAGE (
		KEY		INT,
        LINEAGE VARCHAR(80)
	);

CREATE TABLE CUSTOMER_LINEAGE (
		KEY		INT,
        LINEAGE VARCHAR(80)
	);

\echo 'LOADING nation_lineage'
INSERT INTO nation_lineage VALUES
(1,'<PeerA,nation,1>'),
(2,'<PeerA,nation,2>'),
(3,'<PeerA,nation,3>');
\echo 'LOADING customer_lineage'
INSERT INTO customer_lineage VALUES 
(1,'<PeerA,customer,1>'),
(2,'<PeerA,customer,2>'),
(3,'<PeerA,customer,3>');