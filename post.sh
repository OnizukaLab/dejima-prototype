target=$1
operation=$2
record_id=$3
record_univ=$4

if [ $operation = "insert" ]; then
    curl -v -X POST -H "Content-Type:application/json" -d "{\"transaction_type\":\"original\", \"sql_statements\":[\"INSERT INTO student VALUES (${record_id}, 'FIRST', 'LAST', '${record_univ}');\", \"SELECT * FROM student;\"]}" localhost:800${target}/post_transaction
fi