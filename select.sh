curl -X POST -H "Content-Type:application/json" -d "{\"sql_statements\":[\"SELECT * FROM customer;\"]}" localhost:$1/post_transaction
