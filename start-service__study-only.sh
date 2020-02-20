#!/bin/bash

# -----
# !!! It is not to be used. For study purposes only !!!
#
## Manually create the standalone Container for this microservice.
# -----

NETWORK="microservices"

CONTAINER="movies-service"
IMAGE="$CONTAINER-image"
PORT="3000:3000"

PROJECTDIR=$PWD
SERVICEDIR="Services/Movies-Service"
CONTAINER_APP_DIR="/home/application"

MYSQL_BASH_COMMAND="--default-authentication-plugin=mysql_native_password"

#
# Network.
# Create Network for communication between the microservice,
# MySQL and MongoDB services.
#
function create_network {
  sudo docker network create $NETWORK
}

#
# MySQL Container.
# Create MySQL service Container.
#
function create_service_mysql {
  sudo docker run \
    --network $NETWORK \
    --name mysql-service \
    -e "MYSQL_ROOT_PASSWORD=rootpasswd" \
    -e "MYSQL_DATABASE=movies" \
    -p 3306:3306 \
    -it -d mysql $MYSQL_BASH_COMMAND
}

#
# MongoDB Container.
# Create MongoDB service Container.
#
function create_service_mongodb {
  sudo docker run \
    --network $NETWORK \
    --name mongodb-service \
    -e "MONGO_INITDB_ROOT_USERNAME=root" \
    -e "MONGO_INITDB_ROOT_PASSWORD=rootpasswd" \
    -p 27017:27017 \
    -d mongo
}

#
# Container.
# Create microservice Container.
#
function create_microservice_container {
  # Remove container.
  sudo docker rm $CONTAINER --force;
  # Build image.
  sudo docker build -t $IMAGE .;
  # Run container.
  sudo docker run \
    --network $NETWORK \
    -v $PROJECTDIR/$SERVICEDIR/src:$CONTAINER_APP_DIR/src \
    -p $PORT \
    --name $CONTAINER \
    -d $IMAGE
}

function main {
  create_network
  create_service_mysql
  create_service_mongodb
  create_microservice_container  
}

main