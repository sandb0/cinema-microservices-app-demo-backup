#!/bin/bash
#
# Create MongoDB containers and Replica Set.
#
# Copyright (c) 2020 Sand Box 0
#

SLAVES=1
MONGODB_VOLUME_NAME="mongodb-storage"
MONGODB_FILES_DIR="./mongodb"
MONGODB_KEYFILE_NAME="mongodb-keyfile"
MONGODB_CONTAINER_NAME_PREFIX="mongodb"

# Container parameters.
CPARAM_RESTART="unless-stopped"
CPARAM_ENV_FILE="$MONGODB_FILES_DIR/env"
CPARAM_PORT="27017:27017"
# MongoDB parameters.
DBPARAM_KEYFILE="/data/keyfile/$MONGODB_KEYFILE_NAME"
DBPARAM_REPLSET="rs1"
DBPARAM_STORAGEENGINE="wiredTiger"
DBPARAM_PORT="27017"

print_title() {
  echo ""
  echo "--------------------------------------------------"
  echo "(MongoDB)" $1
  echo "--------------------------------------------------"
}

print_title_line() {
  echo "------------------------- [ $1 ] -------------------------"
}

allow_docker_machine_shell() {
  # Docker and Docker Swarm commands running inside of Docker Machine, VM.
  eval $(docker-machine env $1)
}

docker_bash_exec() {
  local MACHINE=$1
  local CONTAINER=$2
  local BASH_COMMAND=$3

  allow_docker_machine_shell $MACHINE

  docker exec -i $CONTAINER \
    bash -c "$BASH_COMMAND"
}

get_hosts_string_for_replica_set() {
  # First add Master node.
  local IP=$(docker-machine ip $MASTER_NODE)
  local STRING=' --add-host '$MASTER_NODE:$IP

  for SLAVE in $(seq 1 $SLAVES); do
    IP=$(docker-machine ip $WORKER_NODE-$SLAVE)
    STRING=$STRING' --add-host '$WORKER_NODE-$SLAVE:$IP
  done

  echo $STRING
}

create_container() {
  # Container name. Is the same name of Docker Machine.
  local CONTAINER_NAME="$MONGODB_CONTAINER_NAME_PREFIX-$1"
  local MACHINE=$1
  local HOSTS=$(get_hosts_string_for_replica_set)
  
  print_title "Creating Container '$CONTAINER_NAME'"

  # Create and configure Volume for MongoDB Container.
  create_volume_for_this_container $MACHINE

  allow_docker_machine_shell $MACHINE

  docker run \
    --restart=$CPARAM_RESTART \
    --name $CONTAINER_NAME \
    --hostname $CONTAINER_NAME \
    --env-file $CPARAM_ENV_FILE \
    -v $MONGODB_VOLUME_NAME:/data \
    $HOSTS \
    -p $CPARAM_PORT \
    -d mongo \
      --keyFile $DBPARAM_KEYFILE \
      --replSet $DBPARAM_REPLSET \
      --storageEngine $DBPARAM_STORAGEENGINE \
      --port $DBPARAM_PORT

  sleep 2

  # Wait for MongoDB.

  print_title "Waiting for MongoDB on machine '$MACHINE'"

  local IP=$(docker-machine ip $MACHINE)

  while true; do
    (echo > /dev/tcp/$IP/$DBPARAM_PORT) > /dev/null 2>&1
    RESULT=$?

    if [ $RESULT -eq 0 ]; then
      print_title_line "Done!"

      break
    fi
  done

  sleep 2
}

add_slave_on_replica_set() {
  print_title "Adding Slave node '$1' on Replica Set"

  allow_docker_machine_shell $MASTER_NODE

  RS="rs.add('$1:$DBPARAM_PORT')"
  CMD='mongo --eval "'$RS'" -u $MONGO_REPLICA_ADMIN -p $MONGO_PASS_REPLICA --authenticationDatabase "admin"'

  docker_bash_exec $MASTER_NODE $MASTER_CONTAINER "$CMD"
  sleep 2
}

create_replica_set() {
  print_title "Creating MongoDB Replica Set"

  allow_docker_machine_shell $MASTER_NODE

  # Initiate Replica Set.
  docker_bash_exec $MASTER_NODE $MASTER_CONTAINER "mongo < /data/admin/initiate-replica-set.js"
  sleep 2

  # Create root users.
  docker_bash_exec $MASTER_NODE $MASTER_CONTAINER "mongo < /data/admin/create-user-admin.js"
  sleep 2
}

create_volume_for_this_container() {
  local MACHINE=$1

  print_title "Creating Docker Volume for '$MACHINE'"

  allow_docker_machine_shell $MACHINE

  docker volume create --name $MONGODB_VOLUME_NAME
  sleep 2

  # Configure the Volume.

  local TEMPORARY_CONTAINER_NAME="mongodb-temporary-container-for-volume-configuring"

  # Create a temporary Container for Volume configuring.
  docker run \
    --name $TEMPORARY_CONTAINER_NAME \
    -v $MONGODB_VOLUME_NAME:/data \
    -d mongo

  sleep 2
  
  docker_bash_exec $MACHINE $TEMPORARY_CONTAINER_NAME "mkdir -p /data/keyfile /data/admin"
  sleep 1

  # Copy MongoDB scripts to MongoDB Container.
  docker cp $MONGODB_FILES_DIR/initiate-replica-set.js $TEMPORARY_CONTAINER_NAME:/data/admin/
  docker cp $MONGODB_FILES_DIR/create-user-admin.js $TEMPORARY_CONTAINER_NAME:/data/admin/
  docker cp $MONGODB_FILES_DIR/$MONGODB_KEYFILE_NAME $TEMPORARY_CONTAINER_NAME:/data/keyfile/

  docker_bash_exec $MACHINE $TEMPORARY_CONTAINER_NAME "chown -R mongodb:mongodb /data"
  sleep 1

  # Delete temporary Container.
  docker rm $TEMPORARY_CONTAINER_NAME -f
  sleep 1
}

create_keyfile() {
  print_title "Creating keyfile"

  allow_docker_machine_shell $MASTER_NODE

  local KEYFILE=$MONGODB_FILES_DIR/$MONGODB_KEYFILE_NAME

  openssl rand -base64 741 > $KEYFILE
  chmod 600 $KEYFILE
  sleep 1
}

create_containers_replica_set_mongodb() {
  print_title "Creating Containers for MongoDB"

  # Create Master of MongoDB cluster.
  create_container $MASTER_NODE

  # Create Replica Set.
  create_replica_set

  for SLAVE in $(seq 1 $SLAVES); do
    # Create Slave of MongoDB cluster.
    create_container "$WORKER_NODE-$SLAVE"

    # Add slave node at Replica Set.
    add_slave_on_replica_set "$WORKER_NODE-$SLAVE"
  done
}

main() {
  # Get command line arguments.
  for VALUE in "$@"; do
    case $VALUE in
      --manager_node_template_name=*)
        MASTER_NODE="${VALUE#*=}-1"
        MASTER_CONTAINER="$MONGODB_CONTAINER_NAME_PREFIX-$MASTER_NODE"
        ;;
      --worker_node_template_name=*)
        WORKER_NODE="${VALUE#*=}"
        ;;
      --mongodb-slaves=*)
        SLAVES="${VALUE#*=}"
        ;;
    esac
    shift
  done

  create_keyfile
  create_containers_replica_set_mongodb

  print_title_line "MongoDB Replication Set in Docker Swarm are done!"
}

main "$@"