#!/bin/bash

DOCKER_USER=$DOCKER_USER

for container in $(docker container ls | grep -o "$DOCKER_USER-\w\+"); do
    docker stop "$container" &
done
wait
