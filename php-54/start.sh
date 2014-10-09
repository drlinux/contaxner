#!/bin/bash
docker run -d  -i --name="contaxner-DOMAIN" -p PORT:80 -v ROOT:/var/www/DOMAIN -t contaxner/DOMAIN
