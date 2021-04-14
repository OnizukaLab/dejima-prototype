\SET rid random_zipfian(1, 10000, 1.001)
\SET wid random_zipfian(1, 10000, 1.001)
CALL transaction_B(:rid, :wid);