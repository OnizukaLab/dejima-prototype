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
tmux split-window "crane run gov-peer" &
sleep 10 
tmux split-window "crane run insurance-peer" &
sleep 10
tmux select-pane -U
tmux select-pane -U
tmux select-layout even-vertical
tmux split-window -h "docker exec -it dejima-bank-postgres psql -U postgres"
tmux select-pane -D
tmux split-window -h "docker exec -it dejima-gov-postgres psql -U postgres"
tmux select-pane -D
tmux split-window -h "docker exec -it dejima-insurance-postgres psql -U postgres"
tmux select-pane -U
tmux select-pane -U
tmux select-pane -U
