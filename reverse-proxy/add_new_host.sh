#!/bin/bash
#add_new_domain subdomain.testserver.com subdomain
function check_free_port(){

PORT=81


while true

do

    if (netstat -ln | grep ":$PORT " | grep "LISTEN" > /dev/null); then


        let "PORT++"


    else
        echo $PORT;

        break;

    fi;

done

}


add_new_domain(){

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi


    cp templates/proxy.conf "$2".conf

    sed -i -e "s/DOMAIN/$1/g" "$2".conf

    sed -i -e "s/ALIAS/$2/g" "$2".conf

    sed -i -e "s/PORT/$(check_free_port)/g" "$2".conf

    scp -i insecure_key "$2".conf root@$(docker inspect --format="{{ .NetworkSettings.IPAddress }}" emakina-reverse-proxy):/etc/nginx/conf.d/

    ssh -i insecure_key root@$(docker inspect --format="{{ .NetworkSettings.IPAddress }}" emakina-reverse-proxy) 'mkdir -p /var/log/nginx/log/; touch /var/log/nginx/log/'$1'.error.log; touch /var/log/nginx/log/'$1'.access.log; /etc/init.d/nginx reload'

    rm -f "$2".conf



}

add_new_domain $1 $2
