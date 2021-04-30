#!/bin/bash
# 2019.1.16 Wed Anderson Version 0.0.1
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi -f $(docker images -aq)
