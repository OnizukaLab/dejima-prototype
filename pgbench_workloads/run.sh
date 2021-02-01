workload=$2

if [ $workload=A ]; then
    pgbench -h localhost -p 54321 -U postgres -f workloadA.sql -T30 -c1 -n
    # pgbench -h localhost -p 54321 -U postgres -f workloadA.sql -t1 -c1 -n
fi
