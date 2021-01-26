workload=$2

if [ $workload=A ]; then
    pgbench -h localhost -p 54322 -U postgres -f workloadA.sql -T20 -c1
fi
