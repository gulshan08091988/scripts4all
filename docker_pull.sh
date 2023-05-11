#!/bin/bash
#####################################################################################################
#                                                                                                   #
# Script Name: Volt_purge_pro.sh                                                                    #
#                                                                                                   #
# Description: This script is used to purge data                                                    #
#                                                                                                   #
# Owner: Gulshan Sharma                                                                             #
# Email Id: gsharma@voltactivedata.com                                                              #
# Mobile Number: +918800786640                                                                      #
#                                                                                                   #
#####################################################################################################
# specify your Docker Hub username
read -p "Enter Docker Accout User Name: " docker_username
DOCKER_USERNAME=$docker_username
# specify your Docker Hub password
read -p "Enter Docker User Password: " docker_passwd
#DOCKER_PASSWORD=Volt@2022
DOCKER_PASSWORD=$docker_passwd

# specify the name of the repository that you want to download
START_NAME=voltdb
read -p "Enter Docker Repository Name: " docker_repo
REPO_NAME=$docker_repo
read -p "Enter Docker Repository version you want to pull: " repo_version
version=$repo_version

if [[ "$(docker images -q $START_NAME/$REPO_NAME:$version 2> /dev/null)" == "" ]]; then
    # If the Docker image doesn't exist, pull the image from Docker Hub
    echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
    docker pull $START_NAME/$REPO_NAME:$version
    docker save -o $REPO_NAME.tar $START_NAME/$REPO_NAME:$version
else
    # If the Docker image already exists, display a message
    echo "The Docker image $DOCKER_IMAGE_NAME already exists on this machine."
    docker save -o $REPO_NAME.tar $START_NAME/$REPO_NAME:$version
fi

# log out of Docker Hub
docker logout
