#!/bin/bash
docker run -d  -i --name="contaxner-DOMAIN" -p PORT:80 -p 22 -v ROOT:/var/www/DOMAIN:rw -v /data/mysql/DOMAIN:/var/lib/mysql:rw -t contaxner/DOMAIN
