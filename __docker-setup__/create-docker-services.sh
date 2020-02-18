#!/bin/bash
#
# Create with Docker the microservices.
#
# Copyright (c) 2020 Sand Box 0
#

MICROSERVICES=(
  "./Services/Movies-Service"
)

print_title() {
  echo "--------------------------------------------------"
  echo $1
  echo "--------------------------------------------------"
}

main() {
  # Back to root project directory.
  cd ..

  # Get command line arguments.
  for VALUE in "$@"; do
    case $VALUE in
      --use-swarm)
        USE_SWARM="--use-swarm"
        ;;
      --use-local=*)
        USE_LOCAL_IMAGE_REPOSITORY="${VALUE#*=}"
        IMAGE_REPOSITORY_PORT="${VALUE#*=}"
        ;;
      --use-hub=*)
        USE_HUB_IMAGE_REPOSITORY="${VALUE#*=}"
        DOCKER_HUB_USERNAME="${VALUE#*=}"
        ;;
    esac
    shift
  done

  # Build each microservice Docker Image.
  for ((i = 0; i < ${#MICROSERVICES[@]}; ++i)); do
    # Go to microservice directory.
    cd ${MICROSERVICES[$i]}
    
    # Image name is the microservice directory name.
    IMAGE_NAME=$(echo ${MICROSERVICES[$i]} | cut -d '/' -f 3 | awk '{print tolower($0)}')

    # Service Image location: local, local repository or Docker Hub.
    IMAGE=$IMAGE_NAME
    if [ ! -z "$USE_LOCAL_IMAGE_REPOSITORY" ]; then
      IMAGE=localhost:$IMAGE_REPOSITORY_PORT/$IMAGE_NAME
    elif [ ! -z "$USE_HUB_IMAGE_REPOSITORY" ]; then
      IMAGE=$DOCKER_HUB_USERNAME/$IMAGE_NAME
    fi

    bash ./create-service.sh $IMAGE_NAME $IMAGE $USE_SWARM

    cd ..
  done
}

main "$@"
