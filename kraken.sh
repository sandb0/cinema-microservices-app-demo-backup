#!/bin/bash
#
# kraken - Up microservices with Docker.
#
# Create Docker Images.
# Create local Images repository and push. Or only push Images to Docker Hub.
# Create Docker Swarm.
# Create MongoDB replication.
#
# Copyright (c) 2020 Sand Box 0
#

# --------------------------------------------------
# Config variables.
# --------------------------------------------------

# It's a template, it will look like this: "manager-node1", "manager-node2" ...
# If change this name, remember to change the name in `__docker-setup__/mongodb/initiate-replica-set.js`.
MANAGER_NODE_TEMPLATE_NAME="manager-node"

# It's a template, it will look like this: "worker-node1", "worker-node2" ...
WORKER_NODE_TEMPLATE_NAME="worker-node"


print_title() {
  echo ""
  echo "--------------------------------------------------"
  echo ">>> "$1
  echo "--------------------------------------------------"
}

print_usage() {
  echo "Usage: bash kraken.sh [OPTIONS]
  
    Options:
      -s, --swarm                               Start up with Docker Swarm, but keep machines.
      -S, --swarm-reset-machines                Start up with Docker Swarm, but leave Swarm and recreates the machines.
      --swarm-managers=<number>                 Amount of Swarm node managers.
      --swarm-workers=<number>                  Amount of Swarm node workers.
      --swarm-disk-size=<number>                Amount of virtual machine disk size.
      --swarm-memory=<number>                   Amount of virtual machine memory.
      --mongodb-slaves=<number>                 Amount of MongoDB slaves. Amount of Slaves cannot be greater than the amount of Swarm Workers.
      -h <username>, --use-hub=<username>       Use Docker Hub for remote Image repository.
      -l, --use-local                           Use local Container for remote Image repository.
  "
  exit 1
}

print_usage_error() {
  echo "error: invalid option '$1'"
  #echo "Try 'bash kraken.sh --help' for more information."
  print_usage
}

print_status_message() {
  if [ ! -z $USE_SWARM ]; then
    echo "Docker Swarm: on. Creating VMs, Docker Swarm."
  else
    echo "Docker Swarm: off. Creating Docker Containers."
  fi

  if [ -z "$USE_HUB" ] && [ -z "$USE_LOCAL" ]; then
    echo "No use Image repository. Using local Images."
  else
    if [ ! -z "$USE_LOCAL" ]; then
      echo "Use Container for Image repository."
    fi

    if [ ! -z "$USE_HUB" ]; then
      echo "Use Docker Hub for Image repository."
    fi
  fi
}

create_mongodb_replication() {
  cd __docker-setup__

  print_title "Creating MongoDB containers and Replica Set"

  sudo bash create-mongodb-containers.sh  --manager_node_template_name=$MANAGER_NODE_TEMPLATE_NAME --worker_node_template_name=$WORKER_NODE_TEMPLATE_NAME

  print_title "Creating MongoDB containers and Replica Set: Done!"

  cd ..
}

create_docker_swarm() {
  cd __docker-setup__

  print_title "Creating Docker Swarm"

  sudo bash create-docker-swarm.sh $SWARM_RESET_MACHINES $SWARM_MANAGERS $SWARM_WORKERS $SWARM_DISK_SIZE $SWARM_MEMORY --manager_node_template_name=$MANAGER_NODE_TEMPLATE_NAME --worker_node_template_name=$WORKER_NODE_TEMPLATE_NAME

  print_title "Creating Docker Swarm: Done!"

  cd ..
}

create_docker_images() {
  cd __docker-setup__
  
  print_title "Creating Docker Images"

  sudo bash create-docker-images.sh $USE_SWARM $USE_LOCAL $USE_HUB --manager_node_template_name=$MANAGER_NODE_TEMPLATE_NAME

  print_title "Creating Docker Images: Done!"

  cd ..
}

create_docker_services() {
  cd __docker-setup__

  print_title "Creating Microservices"

  sudo bash create-docker-services.sh $USE_SWARM $USE_LOCAL $USE_HUB --manager_node_template_name=$MANAGER_NODE_TEMPLATE_NAME

  print_title "Creating Microservices: Done!"

  cd ..
}

main() {
  # Get command line arguments.
  while [ $# -gt 0 ]; do
    case "$1" in
      -s|--swarm)
        USE_SWARM="--use-swarm"
        ;;
      -S|--swarm-reset-machines)
        USE_SWARM="--use-swarm"
        SWARM_RESET_MACHINES="--swarm-reset-machines"
        ;;
      --swarm-managers=*)
        SWARM_MANAGERS="--swarm-managers=${1#*=}"
        ;;
      --swarm-workers=*)
        SWARM_WORKERS="--swarm-workers=${1#*=}"
        ;;
      --swarm-disk-size=*)
        SWARM_DISK_SIZE="--swarm-disk-size=${1#*=}"
        ;;
      --swarm-memory=*)
        SWARM_MEMORY="--swarm-memory=${1#*=}"
        ;;
      --mongodb-slaves=*)
        SLAVES="--mongodb-slaves=${1#*=}"
        ;;
      -h)
        shift
        # `-h`, `--use-hub`, `-l`, `--use-local` cannot be combined. Avoid it.
        if [ -z $IS_IMAGE_REPOSITORY_SETTED ]; then
          IS_IMAGE_REPOSITORY_SETTED="true"
          USE_HUB="--use-hub=${1#*=}"
        fi
        ;;
      --use-hub=*)
        # `-h`, `--use-hub`, `-l`, `--use-local` cannot be combined. Avoid it.
        if [ -z $IS_IMAGE_REPOSITORY_SETTED ]; then
          IS_IMAGE_REPOSITORY_SETTED="true"
          USE_HUB="--use-hub=${1#*=}"
        fi
        ;;
      -l|--use-local)
        # `-h`, `--use-hub`, `-l`, `--use-local` cannot be combined. Avoid it.
        if [ -z $IS_IMAGE_REPOSITORY_SETTED ]; then
          IS_IMAGE_REPOSITORY_SETTED="true"
          USE_LOCAL="--use-local"
        fi
        ;;
      --help)
        print_usage
        ;;
      *)
        print_usage_error $1
        ;;
    esac
    
    shift
  done

  print_status_message

  # In Swarm mode, create Docker Swarm.
  if [ ! -z $USE_SWARM ]; then
    create_docker_swarm
  fi
  
  create_mongodb_replication
  
  create_docker_images
  create_docker_services
}

main "$@"