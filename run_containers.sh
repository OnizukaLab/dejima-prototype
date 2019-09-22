#!/bin/bash

crane stop
crane rm

removecontainers() {
    docker stop $(docker ps -aq)
    docker rm $(docker ps -aq)
}

removecontainers
docker network prune -f
docker volume rm $(docker volume ls --filter dangling=true -q)

echo "start containers"

tmux split-window "crane run bank-peer" &
sleep 10
tmux split-window "crane run bank-client" &
sleep 10 
tmux split-window "crane run gov-peer" &
sleep 10 
tmux split-window "crane run gov-client" &
