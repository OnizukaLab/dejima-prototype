statements[0]="INSERT INTO student VALUES (1, 'Univ1', 'FIRST', 'LAST'), (2, 'Univ1', 'FIRST', 'LAST'), (3, 'Univ1', 'FIRST', 'LAST');"
#statements[1]="INSERT INTO student VALUES (1, 'Univ2', 'FIRST', 'LAST'), (2, 'Univ2', 'FIRST', 'LAST'), (3, 'Univ2', 'FIRST', 'LAST');"
#statements[2]="INSERT INTO student VALUES (1, 'Univ3', 'FIRST', 'LAST'), (2, 'Univ3', 'FIRST', 'LAST'), (3, 'Univ3', 'FIRST', 'LAST');"

for i in "${!statements[@]}"
do
    data="{\"transaction_type\":\"original\", \"sql_statements\":[\"${statements[i]}\"]}"
    curl -X POST -H "Content-Type:application/json" -d "$data" localhost:8001/post_transaction 
    echo;
done

#curl -v -X POST -H "Content-Type:application/json" -d "{\"transaction_type\":\"original\", \"sql_statements\":[\"INSERT INTO student VALUES (${record_id}, 'FIRST', 'LAST', '${record_univ}');\", \"SELECT * FROM student;\"]}" localhost:800${target}/post_transaction