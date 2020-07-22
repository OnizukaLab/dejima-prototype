statements[0]="INSERT INTO student VALUES (1, 'FIRST', 'LAST', 'Univ1'), (2, 'FIRST', 'LAST', 'Univ1'), (3, 'FIRST', 'LAST', 'Univ1');"
statements[1]="INSERT INTO student VALUES (1, 'FIRST', 'LAST', 'Univ2'), (2, 'FIRST', 'LAST', 'Univ2'), (3, 'FIRST', 'LAST', 'Univ2');"
statements[2]="INSERT INTO student VALUES (1, 'FIRST', 'LAST', 'Univ3'), (2, 'FIRST', 'LAST', 'Univ3'), (3, 'FIRST', 'LAST', 'Univ3');"
target=(1 1 1)

for i in "${!statements[@]}"
do
    data="{\"transaction_type\":\"original\", \"sql_statements\":[\"${statements[i]}\"]}"
    curl -X POST -H "Content-Type:application/json" -d "$data" localhost:800${target[i]}/post_transaction 
    echo;
done

#curl -v -X POST -H "Content-Type:application/json" -d "{\"transaction_type\":\"original\", \"sql_statements\":[\"INSERT INTO student VALUES (${record_id}, 'FIRST', 'LAST', '${record_univ}');\", \"SELECT * FROM student;\"]}" localhost:800${target}/post_transaction