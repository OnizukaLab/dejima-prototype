target=$1

docker exec -it ${target}-db psql -U postgres -d postgres
