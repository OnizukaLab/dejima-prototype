CREATE EXTENSION pgrowlocks;

CREATE TABLE customer (
	KEY		SERIAL,
	NAME	CHAR(25),
	ADDRESS		VARCHAR(152)
);

ALTER TABLE customer ADD PRIMARY KEY (KEY);

\echo 'LOADING customer'
INSERT INTO customer VALUES 
(1,'A','Tokyo');

CREATE TABLE CUSTOMER_LINEAGE (
	KEY		INT,
	LINEAGE VARCHAR(80)
);

\echo 'LOADING customer_lineage'
INSERT INTO customer_lineage VALUES 
(1,'<PeerA,customer,1>');