# Dejima Prototype
Dejima Prototype is implemented as API server.

## Definition of base tables and dejima tables (Setting of this demo)
In this demo, there are three peers: Osaka University, Kyoto University, Hosei University.  
Each peer have a common base table, named "student".  
The "student" table is as follows:
```sql
CREATE TABLE student (
  ID int NOT NULL,
  UNIVERSITY varchar(80) NOT NULL,
  FIRST_NAME varchar(80),
  LAST_NAME varchar(80),
  PRIMARY KEY(ID, UNIVERSITY),
```

Osaka and Kyoto share records which belong to "Osaka" or "Kyoto" via dejima table, named "dejima_osaka_kyoto".  
Osaka and Hosei share records which belong to "Osaka" or "Hosei" via dejima table, named "dejima_osaka_hosei".  
For example, definition of dejima_osaka_kyoto in Osaka is as follows:
```sql
SELECT * FROM student WHERE university = 'Osaka' OR university = 'Kyoto'
```

In addition, there are constraints as follows:
1. In Osaka University, "UNIVERSITY" attribute of records is one of Osaka, Kyoto, or Hosei.
2. In Kyoto University, "UNIVERSITY" attribute of records is one of Osaka or Kyoto.
3. In Hosei University, "UNIVERSITY" attribute of records is one of Osaka or Hosei.

## How to build
You can build this api server just by executing `docker-compose up`.  
`docker-compose up` command builds three containers:
- Nginx   
Reverse Proxy. Port=433. Service name='univ-nginx'.
- falcon + gunicorn  
API server. Port=8000. Service name='univ-proxy'
- PostgreSQL  
DB. Port=5432. Service name='univ-db'

This API server use http **without SSL**, but this server accepts requests at **443 port**.
If you already use some reverse proxy, you can build only two containers on the bottom, just by executing `docker-compose up univ-db univ-proxy`

## Configuration files
- docker-compose.yml  
A configuration file for container orchestration.  
Please set the peer name for 'univ-db' and 'univ-proxy' as a environment variable.

- proxy/dejima_config.json  
A configuration file for proxy.  
Please set the peer address.

- nginx/nginx.conf  
A configuration file for nginx.  
Please set IP address restriction.

## How to call api
### 1. Posting an arbitary transaction (POST /post_transaction)
You can post your own transaction by calling /post_transaction.\
Please POST json data to /post_transaction as follows:
```bash
statements1="INSERT INTO student VALUES (1, 'Osaka', 'FIRST', 'LAST'), (2, 'Kyoto', 'FIRST', 'LAST'), (3, 'Hosei', 'FIRST', 'LAST');"
statements2="DELETE FROM student WHERE id = 3 AND university = 'Hosei'"
data="{\"sql_statements\":[\"$statement1\", \"$statement2\"]}"
curl -X POST -H "Content-Type:application/json" -d "$data" localhost:443/post_transaction 
```

### 2. Add a single student (GET /add_student)
You can add a single student by calling /add_student.\
Please access /add_student with parameters as follows:
```bash
curl "localhost:443/add_student?id=4&university=Osaka&first_name=FIRST&last_name=LAST"
```

### 3. Delete a single student (GET /delete_student)
You can delete a single student by calling /delete_student.\
Please access /delete_student with parameters as follows:
```bash
curl "localhost:443/delete_student?id=4&university=Osaka"
```

### 4. Get all student list (GET /get_student_list)
You can get all student list by calling /get_student_list.\
Please access /get_student_list.
```bash
curl "localhost:443/get_student_list"
```