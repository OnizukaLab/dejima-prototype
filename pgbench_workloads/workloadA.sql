\SET id1 random_zipfian(1, 3, 1.001)
\SET id2 random_zipfian(1, 3, 1.001)
\SET v random(1, 10)
CALL transaction_A(:id1, :id2, ':v');