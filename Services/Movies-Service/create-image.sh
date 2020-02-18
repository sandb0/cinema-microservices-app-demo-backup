#!/bin/bash
#
# Create Docker Image.
#
# Copyright (c) 2020 Sand Box 0
#

# Image name is the microservice directory name.
#IMAGE_NAME=$(echo $PWD | rev | cut -d '/' -f 1 | rev | awk '{print tolower($0)}')
IMAGE_NAME=$1

print_title() {
  echo "--------------------------------------------------"
  echo $1
  echo "--------------------------------------------------"
}

# Clean up Container|Service, Image and Volume.
sudo docker rm $IMAGE_NAME --force
sudo docker rmi $IMAGE_NAME
sudo docker image prune --force
sudo docker volume prune --force

# Build Image.
print_title "Building '$IMAGE_NAME' microservice Image"
sudo docker build -t $IMAGE_NAME .