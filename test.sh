statements[0]="INSERT INTO student VALUES (1, 'Osaka', 'FIRST1', 'LAST'), (2, 'Osaka', 'FIRST2', 'LAST'), (3, 'Osaka', 'FIRST3', 'LAST');"
statements[1]="DELETE FROM student WHERE first_name = 'FIRST1';"
statements[2]="UPDATE student SET last_name = 'NEW_LAST' WHERE first_name = 'FIRST2';"

for i in "${!statements[@]}"
do
    data="{\"sql_statements\":[\"${statements[i]}\"]}"
    curl -X POST -H "Content-Type:application/json" -d "$data" localhost:8000/post_transaction 
    echo;
done
