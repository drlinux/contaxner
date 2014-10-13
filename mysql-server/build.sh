#!/bin/bash
clear
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi
if [[$( /usr/bin/docker rm contaxner/mysql-server)]]; then echo "Old container removed"; fi
echo "Building docker image... Please be patient... This may take some time..."

/usr/bin/docker build -t contaxner/mysql-server .

curl -o insecure_key -fSL https://github.com/phusion/baseimage-docker/raw/master/image/insecure_key

chmod 600 insecure_key

echo "Runing the container"

/usr/bin/docker run -d -i --name="contaxner-mysql-server" -t contaxner/mysql-server

/usr/bin/docker stop contaxner-mysql-server

echo " ./run.sh"
