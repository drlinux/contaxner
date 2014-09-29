#!/bin/bash
clear
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi
if [[$( /usr/bin/docker rm cheri-cart)]]; then echo "Old container removed"; fi
echo "Building docker image... Please be patient... This may take some time..."

/usr/bin/docker build -t emakina/nginx-reverse-proxy .

curl -o insecure_key -fSL https://github.com/phusion/baseimage-docker/raw/master/image/insecure_key

chmod 600 insecure_key

echo "Runing the container"

/usr/bin/docker run -d -i --name="emakina-reverse-proxy" -t emakina/nginx-reverse-proxy

/usr/bin/docker stop emakina-reverse-proxy

echo " ./run.sh"
