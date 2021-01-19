\SET id1 random_zipfian(1, 3, 1.001)
\SET id2 random_zipfian(1, 3, 1.001)
\SET v random(1, 10)
BEGIN;
SELECT * FROM bt_lineage WHERE id=:id1 FOR SHARE NOWAIT;
SELECT * FROM bt_lineage WHERE id=:id2 FOR UPDATE NOWAIT;
SELECT * FROM bt WHERE id = :id1;
UPDATE bt SET col1=':v' WHERE id=:id2;
END;