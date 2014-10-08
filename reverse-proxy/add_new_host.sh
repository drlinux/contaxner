#!/bin/bash
#add_new_domain subdomain.testserver.com subdomain

PATTERN="^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$";
TEMP=/tmp/answer.$$
MENU_INPUT=/tmp/menu.sh.$$
MENU_OUTPUT=/tmp/output.sh.$$
TEMP=/tmp/answer.$$

ask_repo_address(){

    tput clear

    dialog --screen-center --title "Personal / Private SCM URL" --inputbox "Enter your repo URL below:" 8 40 2> $TEMP

    REPO_URL=`cat $TEMP`

    rm -f $TEMP

    install_sources $1 $REPO_URL $2

    exit
}

check_free_port(){

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

#add_new_domain alias domain.name

add_new_domain(){


    if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi


    cp templates/proxy.conf "$2".conf

    sed -i -e "s/DOMAIN/$1/g" "$2".conf

    sed -i -e "s/ALIAS/$2/g" "$2".conf

    sed -i -e "s/PORT/$(check_free_port)/g" "$2".conf

    scp -i insecure_key "$2".conf root@$(docker inspect --format="{{ .NetworkSettings.IPAddress }}" contaxner-reverse-proxy):/etc/nginx/conf.d/


    ssh -i insecure_key root@$(docker inspect --format="{{ .NetworkSettings.IPAddress }}" contaxner-reverse-proxy) 'mkdir -p /var/log/nginx/log/; touch /var/log/nginx/log/'$1'.error.log; touch /var/log/nginx/log/'$1'.access.log; /etc/init.d/nginx reload'

    docker commit -m "ADD new host : $1" $(docker inspect --format="{{ .Config.Hostname }}" contaxner-reverse-proxy) contaxner/nginx-reverse-proxy:latest

    rm -f "$2".conf

    #let's create docker host container for the domain.
    #but, we need some information for the host container such as php version, project type etc..
    #we need project type because nginx needs differend kind of virtual host configurations
    #for each project type
    #this section heavily inspired from the mynxer project

    #create a directory for the domain
    #we'll store the Docker file and (if there are some) neccessary files in the directory
    #for access easily later.

    mkdir -p ~/contaxner-dockerfiles/$1/

    while true
    do

        ### ask for php version ###


        dialog --clear \
            --title "Project Type" \
            --menu "Please Choose the PHP version" 15 50 4 \
            PHP 5.4.x "PHP 5.4.x" \
            PHP 5.5.x "PHP 5.5.x" \
            Exit "Exit to the shell" 2>"${MENU_INPUT}"

        usersphpselection=$(<"${MENU_INPUT}")

        if [ "$usersphpselection" = 'Exit' ]; then

            echo "Bye"; break;

        elif [ "$usersphpselection" = 'PHP 5.4.x'  ]; then

            cp -rf php-54/* ~/contaxner-dockerfiles/$1/


        elif [ "$usersphpselection" = 'PHP 5.5.x' ]; then

            cp -rf php-55/* ~/contaxner-dockerfiles/$1/


        fi

        # if temp files exists, destroy`em all!


        [ -f $MENU_OUTPUT ] && rm $MENU_OUTPUT
        [ -f $MENU_INPUT ] && rm $MENU_INPUT

    done

    #ask for the project type

    while true
    do


        ### display main menu ###

        dialog --clear \
            --title "Project Type" \
            --menu "Please Choose the Project Type" 15 50 4 \
            Magento "Magento Project" \
            Prestashop "Prestashop Project" \
            Wordpress "Wordpress Project" \
            Laravel "Laravel Project" \
            Other "Generic PHP / HTML Project" 2>"${MENU_INPUT}"

        userselection=$(<"${MENU_INPUT}")

        if [ "$userselection" = 'Magento' ]; then

            THE_REPO="https://github.com/magento/magento2.git"

        elif [ "$userselection" = 'Prestashop' ]; then

            THE_REPO="https://github.com/PrestaShop/PrestaShop.git"

        elif [ "$userselection" = 'Laravel' ]; then

            THE_REPO="https://github.com/laravel/laravel.git"
            ask_clone_question "$userselection" "$THE_REPO" "$WEB_DIR"/"$USERNAME"/public_html

        elif [ "$userselection" = 'Wordpress' ]; then

            THE_REPO="https://github.com/WordPress/WordPress.git"

        fi

            echo 'ADD www.conf /etc/php5/fpm/pool.d/www.conf' >> ~/contaxner-dockerfiles/$1/Dockerfile


            echo 'ADD php.ini /etc/php5/fpm/php.ini' >> ~/contaxner-dockerfiles/$1/Dockerfile

            cp -f virtual-host-templates/virtual_host_"$userselection".template ~/contaxner-dockerfiles/$1/nginx-site.conf

            echo 'ADD nginx-site.conf /etc/nginx/sites-available/default' >> ~/contaxner-dockerfiles/$1/Dockerfile


            echo "RUN sed -i -e 's/^listen =.*/listen = \/var\/run\/php5-fpm.sock/' /etc/php5/fpm/pool.d/www.conf" >> ~/contaxner-dockerfiles/$1/Dockerfile

            echo 'RUN sed -i "s/DOMAIN/$DOMAIN/g" /etc/nginx/sites-available/default' >> ~/contaxner-dockerfiles/$1/Dockerfile

            echo 'RUN sed -i "s#ROOT#\/data\/www\/$1#g" /etc/nginx/sites-available/default'  >> ~/contaxner-dockerfiles/$1/Dockerfile


            echo 'RUN apt-get install -y screen' >> ~/contaxner-dockerfiles/$1/Dockerfile


            echo 'RUN chmod 777 /var/run/screen' >> ~/contaxner-dockerfiles/$1/Dockerfile

            [ -f $MENU_OUTPUT ] && rm $MENU_OUTPUT
            [ -f $MENU_INPUT ] && rm $MENU_INPUT


            dialog --clear \
                --title "SCM" \
                --menu "Please Choose the Project Files Source" 15 50 4 \
                Github "Get most recent code from Github" \
                Git "Personal Git Repo" \
                SVN "Personal SVN Repo" 2>"${MENU_INPUT}"

                userscmselection=$(<"${MENU_INPUT}")

                if [ "$userscmselection" = 'Github' ]; then


                    echo 'RUN git clone $THE_REPO /data/www/$1/' >> ~/contaxner-dockerfiles/$1/Dockerfile

                elif [ "$userscmselection" = 'Git' ]; then

                    tput clear

                    dialog --screen-center --title "Personal / Private SCM URL" --inputbox "Enter your repo URL below:" 8 40 2> $TEMP

                    REPO_URL=`cat $TEMP`

                    rm -f $TEMP

                    echo 'RUN git clone $REPO_URL /data/www/$1/' >> ~/contaxner-dockerfiles/$1/Dockerfile

                elif [ "$userscmselection" = 'SVN' ]; then


                    echo 'RUN sudo apt-get install -y subversion'  >> ~/contaxner-dockerfiles/$1/Dockerfile


                    echo 'RUN svn checkout $REPO_URL /data/www/$1/' >> ~/contaxner-dockerfiles/$1/Dockerfile


                fi

            echo 'EXPOSE 80' >> ~/contaxner-dockerfiles/$1/Dockerfile


            echo 'EXPOSE 3306' >> ~/contaxner-dockerfiles/$1/Dockerfile

            #And Start

            echo 'CMD service mysql start; php5-fpm; nginx -c /etc/nginx/nginx.conf' >> ~/contaxner-dockerfiles/$1/Dockerfile

            [ -f $MENU_OUTPUT ] && rm $MENU_OUTPUT

            [ -f $MENU_INPUT ] && rm $MENU_INPUT

            ### DOCKER FILE GENERATED ####

            #Now we'll create our host containder from the Dockerfile



    done

    exit



}

add_new_domain $1 $2

