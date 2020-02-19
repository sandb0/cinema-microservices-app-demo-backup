#!/bin/bash
#
# Create Swarm.
#
# Copyright (c) 2020 Sand Box 0
#

MANAGERS=1
WORKERS=2
DISK_SIZE="5000"
MEMORY="1024"

MANAGER_NODE=manager-node1
DOCKER_MACHINE_DRIVER="virtualbox"
ADDITIONAL_PARAMS=

print_title() {
  echo ""
  echo "--------------------------------------------------"
  echo "(Swarm)" $1
  echo "--------------------------------------------------"
}

get_machine_ip() {
  echo $(docker-machine ip $1)
}

get_machine_worker_token() {
  local COMMAND="docker-machine ssh $MANAGER_NODE \
    docker swarm join-token worker -q"

  echo $($COMMAND)
}

leave_swarm() {
  print_title "Leaving Swarm"

  docker-machine ssh $MANAGER_NODE \
    docker swarm leave --force

  for MANAGER in $(seq 1 $MANAGERS); do
    local MACHINE=$(docker-machine ls --filter name="manager-node$MANAGER" -q)

    if [ ! -z $MACHINE ]; then
      print_title "Removing VM 'manager-node$MANAGER'"

      docker-machine rm manager-node$MANAGER --force
    fi
  done

  for WORKER in $(seq 1 $WORKERS); do
    local MACHINE=$(docker-machine ls --filter name="worker-node$WORKER" -q)

    if [ ! -z $MACHINE ]; then
      print_title "Removing VM 'worker-node$WORKER'"

      docker-machine rm worker-node$WORKER --force
    fi
  done
}

create_manager_nodes() {
  for MANAGER in $(seq 1 $MANAGERS); do
    print_title "Creating VM 'manager-node$MANAGER'"
    
    docker-machine create --driver $DOCKER_MACHINE_DRIVER $ADDITIONAL_PARAMS manager-node$MANAGER
  done
}

create_worker_nodes() {
  for WORKER in $(seq 1 $WORKERS); do
    print_title "Creating VM 'worker-node$WORKER'"

    docker-machine create --driver $DOCKER_MACHINE_DRIVER $ADDITIONAL_PARAMS worker-node$WORKER
  done
}

start_swarm() {
  print_title "Starting Swarm"

  docker-machine ssh $MANAGER_NODE \
    docker swarm init --advertise-addr $(get_machine_ip $MANAGER_NODE)
}

join_worker_nodes() {
  for WORKER in $(seq 1 $WORKERS); do
    print_title "Worker Node 'worker-node$WORKER' joining to Swarm"

    docker-machine ssh worker-node$WORKER \
      docker swarm join --token $(get_machine_worker_token) $(get_machine_ip $MANAGER_NODE):2377
  done
}

print_status() {
  print_title "Listing virtual machines"

  docker-machine ls

  print_title "Listing nodes in the Swarm"

  docker-machine ssh $MANAGER_NODE \
    docker node ls
}

start_rancher_server() {
  print_title "Starting the Rancher Server to monitor the cluster"

  docker-machine ssh $MANAGER_NODE \
    docker run --name rancher --restart=unless-stopped -p 9000:8080 -d rancher/server

  print_title "Rancher Server monitor access: $(get_machine_ip $MANAGER_NODE):9000"
}

main() {
  #leave_swarm

  # Get command line arguments.
  for VALUE in "$@"; do
    case $VALUE in
      --swarm-managers=*)
        MANAGERS=${VALUE#*=}
        ;;
      --swarm-workers=*)
        WORKERS=${VALUE#*=}
        ;;
      --swarm-disk-size=*)
        DISK_SIZE="${VALUE#*=}"
        ;;
      --swarm-memory=*)
        MEMORY="${VALUE#*=}"
        ;;
    esac
    shift
  done

  # Params for VirtualBox machines.
  if [ $DOCKER_MACHINE_DRIVER == "virtualbox" ]; then
    print_title "Creating Docker Swarm with $MANAGERS node manager(s) and $WORKERS node worker(s) on $DOCKER_MACHINE_DRIVER machines"

    ADDITIONAL_PARAMS="--virtualbox-disk-size ${DISK_SIZE} --virtualbox-memory ${MEMORY}"
  fi

  create_manager_nodes
  create_worker_nodes
  start_swarm
  join_worker_nodes

  #start_rancher_server
  print_status
}

main "$@"