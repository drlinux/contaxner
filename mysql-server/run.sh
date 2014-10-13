#!/bin/bash
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi
clear

docker rm -f "contaxner-mysql-server" > /dev/null

/usr/bin/docker run -i -d --name="contaxner-mysql-server" -p 3306:3306 -v /data/mysql:/var/lib/mysql:rw -t "contaxner/mysql-server" > /dev/null

echo "Congrats! Mysql Server Container Successfully Started!";
