#!/bin/bash
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi
clear

docker rm -f "contaxner-reverse-proxy" > /dev/null

/usr/bin/docker run -i -d --name="contaxner-reverse-proxy" -p 80 -t "contaxner/nginx-reverse-proxy" > /dev/null

CONTAINER_IP=$(/usr/bin/docker inspect --format="{{ .NetworkSettings.IPAddress }}" contaxner-reverse-proxy)

echo "Congrats! Reverse Proxy Successfully Started";
