statements[0]="INSERT INTO student VALUES (1, 'Osaka', 'FIRST', 'LAST'), (2, 'Kyoto', 'FIRST', 'LAST'), (3, 'Hosei', 'FIRST', 'LAST');"

for i in "${!statements[@]}"
do
    data="{\"transaction_type\":\"original\", \"sql_statements\":[\"${statements[i]}\"]}"
    curl -X POST -H "Content-Type:application/json" -d "$data" localhost:8000/post_transaction 
    echo;
done
