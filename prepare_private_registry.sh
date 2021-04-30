#!/bin/bash
# 2021.3.27 Sat Version 0.0.1
#           Anderson Wang
##########################
HOST=10.0.1.104

rm -rf /opt/data/registry
mkdir -p /opt/data/registry

rm -f registry.tar.gz > /dev/null 2>&1
wget $HOST/FTPRoot/Docker/DockerImages/registry.tar.gz

docker stop registry-srv > /dev/null 2>&1
docker rm registry-srv > /dev/null 2>&1
docker rmi registry -f > /dev/null 2>&1

docker load -i registry.tar.gz

docker run -d -p 5000:5000 -v /opt/data/registry:/var/lib/registry --restart=always --name registry-srv registry

rm -f docker-registry-web.tar.gz > /dev/null 2>&1
wget $HOST/FTPRoot/Docker/DockerImages/docker-registry-web.tar.gz

docker stop registry-web-1 > /dev/null 2>&1
docker rm registry-web-1 > /dev/null 2>&1
docker rmi hyper/docker-registry-web -f /dev/null 2>&1

docker load -i docker-registry-web.tar.gz

docker run -d -p 8080:8080 --name registry-web-1 --link registry-srv -e REGISTRY_URL=http://registry-srv:5000/v2 -e REGISTRY_NAME=localhost:5000 hyper/docker-registry-web

for i in alpine alpine-bash httpd mariadb mysql mysql-5.5 mysql-5.6 nginx ubuntu wordpress
do
  echo ${i}
  rm -f ${i}.tar.gz > /dev/null 2>&1
  wget $HOST/FTPRoot/Docker/DockerImages/${i}.tar.gz
  docker rmi ${i} -f > /dev/null 2>&1
  docker load -i ${i}.tar.gz
  docker tag ${i} localhost:5000/${i}:v1
  docker push localhost:5000/${i}:v1
done

docker tag mysql:5.5 localhost:5000/mysql:5.5
docker push localhost:5000/mysql:5.5
docker tag mysql:5.6 localhost:5000/mysql:5.6
docker push localhost:5000/mysql:5.6

rm -f docker-python-flask-demo.tar.gz > /dev/null 2>&1
wget $HOST/FTPRoot/Docker/DockerImages/docker-python-flask-demo.tar.gz

docker rmi kdchang/docker-python-flask-demo:v1 -f > /dev/null 2>&1

docker load -i docker-python-flask-demo.tar.gz
docker tag kdchang/docker-python-flask-demo:v1 localhost:5000/docker-python-flask-demo:v1
docker push localhost:5000/docker-python-flask-demo:v1

curl 127.0.0.1:5000/v2/_catalog

firefox http://192.168.66.21:8080
