#!/bin/bash
#
# Create Docker Images.
#
# Copyright (c) 2020 Sand Box 0
#

MICROSERVICES=(
  "./Services/Movies-Service"
)

IMAGE_REPOSITORY_NAME="registry"

print_title() {
  echo ""
  echo "--------------------------------------------------"
  echo "(Images)" $1
  echo "--------------------------------------------------"
}

allow_docker_machine_shell() {
  # Docker and Docker Swarm commands running inside of Docker Machine, VM.
  eval $(docker-machine env $1)
}

use_insecure_registries() {
  # Enable insecure Docker Registry with HTTP instead of HTTPS.

  # If file not exists, make the copy.
  if [ ! -f "/etc/docker/daemon.json.bkp" ]; then
    cp /etc/docker/daemon.json /etc/docker/daemon.json.bkp
  fi

  echo "{ \"insecure-registries\": [\"$(docker-machine ip $1):5000\"] }" > /etc/docker/daemon.json

  systemctl daemon-reload
  service docker restart
}

create_local_image_repository() {
  # Create local (Container) Image repository.
  if [ ! -z "$USE_LOCAL_IMAGE_REPOSITORY" ]; then
    allow_docker_machine_shell $MANAGER_NODE

    # In Swarm mode, create a Service.
    if [ ! -z $USE_SWARM ]; then
      local REGISTRY_SERVICE=$(docker service ls --filter name="$IMAGE_REPOSITORY_NAME" -q)

      if [ -z $REGISTRY_SERVICE ]; then
        print_title "Creating local service for Image repository."
        docker service create --name $IMAGE_REPOSITORY_NAME --publish 5000:5000 registry:2
        use_insecure_registries $MANAGER_NODE
      fi
    # Or, create a Container.
    else
      local REGISTRY_CONTAINER=$(docker ps --filter name="$IMAGE_REPOSITORY_NAME" -q)

      if [ -z $REGISTRY_CONTAINER ]; then
        print_title "Creating local container for Image repository."
        docker run -p 5000:5000 --name $IMAGE_REPOSITORY_NAME -d registry
      fi
    fi
  fi
}

push_image_to_repository() {
  local IMAGE_NAME=$1

  # To Docker Hub.
  if [ ! -z "$USE_HUB_IMAGE_REPOSITORY" ]; then
    local IMAGE_ID=$(docker images -q $IMAGE_NAME)

    print_title "Pushing '$IMAGE_NAME' Image to Docker Hub"

    sudo docker tag $DOCKER_HUB_USERNAME/$IMAGE_ID $IMAGE_NAME:latest
    sudo docker push $DOCKER_HUB_USERNAME/$IMAGE_NAME:latest

    sudo docker rmi $IMAGE_NAME
  # To local Docker Container.
  elif [ ! -z "$USE_LOCAL_IMAGE_REPOSITORY" ]; then
    local IMAGE_ID=$(docker images -q $IMAGE_NAME)

    print_title "Pushing '$IMAGE_NAME' Image to local Image repository"

    allow_docker_machine_shell $MANAGER_NODE

    sudo docker tag $IMAGE_NAME:latest $(docker-machine ip $MANAGER_NODE):5000/$IMAGE_NAME
    sudo docker push $(docker-machine ip $MANAGER_NODE):5000/$IMAGE_NAME

    sudo docker rmi $IMAGE_NAME
  fi
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
      --use-local)
        USE_LOCAL_IMAGE_REPOSITORY="--use-local"
        ;;
      --use-hub=*)
        USE_HUB_IMAGE_REPOSITORY="${VALUE#*=}"
        DOCKER_HUB_USERNAME="${VALUE#*=}"
        ;;
      --manager_node_template_name=*)
        MANAGER_NODE="${VALUE#*=}-1"
        ;;
    esac
    shift

  done

  # Instead of uploading Image to the Docker Hub,
  # upload to a "remote" local (Container) repository.
  create_local_image_repository

  # Build each microservice Docker Image.
  for ((i = 0; i < ${#MICROSERVICES[@]}; ++i)); do
    # Go to microservice directory.
    cd ${MICROSERVICES[$i]}
    
    # Image name is the microservice directory name.
    IMAGE_NAME=$(echo ${MICROSERVICES[$i]} | cut -d '/' -f 3 | awk '{print tolower($0)}')
    
    # Remove and build Docker Image.
    sudo docker rmi $IMAGE_NAME
    bash ./create-image.sh $IMAGE_NAME

    push_image_to_repository $IMAGE_NAME

    cd ..
  done
}

main "$@"