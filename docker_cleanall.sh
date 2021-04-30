#!/bin/bash
# 2019.1.16 Wed Anderson Version 0.0.1
# remove all containers+docker images
#./docker_stop_container.sh
#./docker_rm_container.sh
#./docker_rm_images.sh
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi -f $(docker images -aq)
docker ps -a
docker images
