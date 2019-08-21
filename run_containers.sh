#!/bin/bash

crane stop
crane rm

removecontainers() {
    docker stop $(docker ps -aq)
    docker rm $(docker ps -aq)
}

removecontainers
docker network prune -f
# docker rmi -f $(docker images --filter dangling=true -qa)
docker volume rm $(docker volume ls --filter dangling=true -q)
# docker rmi -f $(docker images -qa)

echo "start containers"

tmux split-window "crane run bank-peer" &
sleep 10
tmux split-window "crane run bank-client" &
sleep 10 
tmux split-window "crane run gov-peer" &
#tmux split-window "docker-compose run --service-ports dejima-bank-client" & 
#sleep 5 
#tmux split-window "docker-compose run --service-ports --name dejima-gov-peer dejima-gov-peer" & 
#sleep 30
#tmux split-window "crane run gov-client"
