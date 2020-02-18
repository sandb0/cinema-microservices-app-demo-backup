#!/bin/bash
#
# kraken - Up microservices with Docker.
#
# Create Docker Images.
# Create local Images repository and push. Or only push Images to Docker Hub.
# Create Docker Swarm.
#
# Copyright (c) 2020 Sand Box 0
#

print_title() {
  echo "--------------------------------------------------"
  echo $1
  echo "--------------------------------------------------"
}

print_usage() {
  echo "Usage: bash kraken.sh [OPTIONS]
  
    Options:
      -s, --swarm                               Start up with Docker Swarm.
      -h <username>, --use-hub=<username>       Use Docker Hub for remote Image repository.
      -l <port>, --use-local=<port>             Use local Container for remote Image repository.
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

create_docker_images() {
  cd __docker-setup__
  
  print_title "Creating Docker Images"

  sudo bash create-docker-images.sh $USE_SWARM $USE_LOCAL $USE_HUB

  cd ..
}

create_docker_services() {
  cd __docker-setup__

  print_title "Creating Microservices"

  sudo bash create-docker-services.sh $USE_SWARM $USE_LOCAL $USE_HUB

  cd ..
}

main() {
  # Get command line arguments.
  while [ $# -gt 0 ]; do
    case "$1" in
      -s|--swarm)
        USE_SWARM="--use-swarm"
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
      -l)
        shift
        # `-h`, `--use-hub`, `-l`, `--use-local` cannot be combined. Avoid it.
        if [ -z $IS_IMAGE_REPOSITORY_SETTED ]; then
          IS_IMAGE_REPOSITORY_SETTED="true"
          USE_LOCAL="--use-local=${1#*=}"
        fi
        ;;
      --use-local=*)
        # `-h`, `--use-hub`, `-l`, `--use-local` cannot be combined. Avoid it.
        if [ -z $IS_IMAGE_REPOSITORY_SETTED ]; then
          IS_IMAGE_REPOSITORY_SETTED="true"
          USE_LOCAL="--use-local=${1#*=}"
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

  create_docker_images
  create_docker_services
}

main "$@"