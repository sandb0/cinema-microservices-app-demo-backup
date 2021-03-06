#!/bin/bash
#
# Create microservice.
#
# Copyright (c) 2020 Sand Box 0
#

# Image name is the microservice directory name.
#IMAGE_NAME=$(echo $PWD | rev | cut -d '/' -f 1 | rev | awk '{print tolower($0)}')
IMAGE_NAME=$1
IMAGE=$2
USE_SWARM=$3

REPLICAS=1
API_ROUTE="/movies"
PORT="3010:3010"

SERVICEDIR=$PWD
CONTAINER_APP_DIR="/home/application"

print_title() {
  echo ""
  echo "--------------------------------------------------"
  echo "(Service)" $1
  echo "--------------------------------------------------"
}

# Create Service in Swarm mode on.
if [ ! -z $USE_SWARM ]; then
  SERVICE=$(docker service ls --filter name="$IMAGE_NAME" -q)

  # Remove service if exists.
  if [ ! -z $SERVICE ]; then 
    docker service rm $SERVICE
    sleep 2
  fi

  print_title "Creating '$IMAGE_NAME' microservice with Docker Swarm using Image repository"

  docker service create \
    --replicas $REPLICAS \
    --name $IMAGE_NAME \
    -l=apiRoute=$API_ROUTE \
    -p $PORT \
    $IMAGE
# Create standalone Container in Swarm mode off.
else
  CONTAINER=$(docker ps --filter name="$IMAGE_NAME" -q)

  # Remove container if exists.
  if [ ! -z $CONTAINER ]; then
    docker rm $CONTAINER
    sleep 2
  fi

  print_title "Creating '$IMAGE_NAME' microservice Container"

  docker run \
    --name $IMAGE_NAME \
    -v $SERVICEDIR/src:$CONTAINER_APP_DIR/src \
    -l=apiRoute=$API_ROUTE \
    -p $PORT \
    -d $IMAGE
fi