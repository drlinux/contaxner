#!/bin/bash
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi
clear

docker rm -f "contaxner-reverse-proxy" > /dev/null

/usr/bin/docker run -i -d --name="contaxner-reverse-proxy" -p 80 -t "contaxner/nginx-reverse-proxy" > /dev/null

echo "Congrats! Reverse Proxy Container Successfully Started!";
