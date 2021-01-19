workload=$2

if [ $workload=A ]; then
    pgbench -h localhost -p 54322 -U postgres -f workloadA.sql -T60 -c10
fi