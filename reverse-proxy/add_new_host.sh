#!/bin/bash
#add_new_domain subdomain.testserver.com subdomain

PATTERN="^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$";
TEMP=/tmp/answer.$$
MENU_INPUT=/tmp/menu.sh.$$
MENU_OUTPUT=/tmp/output.sh.$$
TEMP=/tmp/answer.$$

# if temp files exists, destroy`em all!

[ -f $MENU_OUTPUT ] && rm $MENU_OUTPUT
[ -f $MENU_INPUT ] && rm $MENU_INPUT

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



    DOMAIN=$1

    FREE_PORT=$(check_free_port)
    cp templates/proxy.conf "$2".conf

    sed -i -e "s/DOMAIN/$1/g" "$2".conf

    sed -i -e "s/ALIAS/$2/g" "$2".conf

    sed -i -e "s/PORT/$FREE_PORT/g" "$2".conf

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
    #we'll store the Dockerfile and (if there are some) neccessary files in the directory
    #for access easily later.

    mkdir -p ~/contaxner-dockerfiles/$1/

    while true
    do

        ### ask for php version ###


        dialog --clear \
            --title "Project Type" \
            --menu "Please Choose the PHP Version" 15 50 4 \
            'PHP 5.5' "PHP 5.5 (Required)" \
           'PHP 5.4' "PHP 5.4" 2>"${MENU_INPUT}"

        usersphpselection=$(<"${MENU_INPUT}")


        if [ "$usersphpselection" = 'PHP 5.4'  ]; then

            cp -rf ../php-54/* ~/contaxner-dockerfiles/$1/


        elif [ "$usersphpselection" = 'PHP 5.5' ]; then

            cp -rf ../php-55/* ~/contaxner-dockerfiles/$1/


        fi


        # if temp files exists, destroy`em all!


        [ -f $MENU_OUTPUT ] && rm $MENU_OUTPUT
        [ -f $MENU_INPUT ] && rm $MENU_INPUT

        project_type $1 $2


    done
    exit

}

project_type(){

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

        elif [ "$userselection" = 'Wordpress' ]; then

            THE_REPO="https://github.com/WordPress/WordPress.git"

        fi

        echo 'ADD www.conf /etc/php5/fpm/pool.d/www.conf' >> ~/contaxner-dockerfiles/$1/Dockerfile


        echo 'ADD php.ini /etc/php5/fpm/php.ini' >> ~/contaxner-dockerfiles/$1/Dockerfile

        rm -f  ~/contaxner-dockerfiles/$1/nginx-site.conf

        cp -f ../virtual-host-templates/virtual_host_"$userselection".template ~/contaxner-dockerfiles/$1/nginx-site.conf

        echo 'RUN rm -f /etc/nginx/sites-available/default' >> ~/contaxner-dockerfiles/$1/Dockerfile

        echo 'ADD nginx-site.conf /etc/nginx/sites-available/default' >> ~/contaxner-dockerfiles/$1/Dockerfile


        echo "RUN sed -i -e 's/^listen =.*/listen = \/var\/run\/php5-fpm.sock/' /etc/php5/fpm/pool.d/www.conf" >> ~/contaxner-dockerfiles/$1/Dockerfile

        echo 'RUN sed -i "s/DOMAIN/'$DOMAIN'/g" /etc/nginx/sites-available/default' >> ~/contaxner-dockerfiles/$1/Dockerfile

        echo 'RUN sed -i "s/ROOT/\/var\/www\/'$1'/g" /etc/nginx/sites-available/default' >> ~/contaxner-dockerfiles/$1/Dockerfile

        echo 'RUN apt-get install -y screen' >> ~/contaxner-dockerfiles/$1/Dockerfile


        echo 'RUN chmod 777 /var/run/screen' >> ~/contaxner-dockerfiles/$1/Dockerfile

        [ -f $MENU_OUTPUT ] && rm $MENU_OUTPUT
        [ -f $MENU_INPUT ] && rm $MENU_INPUT

        scm_type $1 $2 $THE_REPO

    done
    exit

}

scm_type(){

    THE_REPO=$3

    dialog --clear \
        --title "SCM" \
        --menu "Please Choose the Project Files Source" 15 50 4 \
        Github "Get most recent code from Github" \
        URL "Copy from an URL" \
        Git "Personal Git Repo" \
        SVN "Personal SVN Repo" 2>"${MENU_INPUT}"

    userscmselection=$(<"${MENU_INPUT}")

    if [ "$userscmselection" = 'Github' ]; then

        tput clear

        git clone $THE_REPO /data/www/$1

    elif [ "$userscmselection" = 'Git' ]; then

        tput clear

        dialog --screen-center --title "Personal / Private SCM URL" --inputbox "Enter your repo URL below:" 8 40 2> $TEMP

        REPO_URL=`cat $TEMP`

        rm -f $TEMP

        git clone $REPO_URL /data/www/$1

    elif [ "$userscmselection" = 'URL' ]; then

        tput clear

        mkdir -p /data/www/$1

        REPO_URL='http://www.magentocommerce.com/downloads/assets/1.9.0.1/magento-1.9.0.1.tar.gz'

        cd /data/www/$1 && wget $REPO_URL && tar zxvf magento-1.9.0.1.tar.gz && mv magento/* . && rm -rf magento/ && rm -rf magento-1.9.0.1.tar.gz

        tar zxvf magento-1.9.0.1.tar.gz

    elif [ "$userscmselection" = 'SVN' ]; then


        sudo apt-get install -y subversion


        svn checkout $REPO_URL /data/www/$1


    fi
    container_settings $1 $2
    exit

}

container_settings(){

    echo 'EXPOSE 80' >> ~/contaxner-dockerfiles/$1/Dockerfile


    echo 'EXPOSE 3306' >> ~/contaxner-dockerfiles/$1/Dockerfile

    #RUN composer update for Laravel project

    if [ "$userselection" = 'Laravel' ]; then


       cd /data/www/$1 && composer update

    elif [ "$userselection" = 'Magento' ]; then




        echo 'RUN chmod 0777 /var/www/'$1'/app/etc' >> ~/contaxner-dockerfiles/$1/Dockerfile
        echo 'RUN chmod 0777 /var/www/'$1'/media' >> ~/contaxner-dockerfiles/$1/Dockerfile
        echo 'RUN chmod 0777 /var/www/'$1'/media/xmlconnect' >> ~/contaxner-dockerfiles/$1/Dockerfile
        echo 'RUN chmod 0777 /var/www/'$1'/media/xmlconnect/custom' >> ~/contaxner-dockerfiles/$1/Dockerfile
        echo 'RUN chmod 0777 /var/www/'$1'/media/xmlconnect/custom/ok.gif' >> ~/contaxner-dockerfiles/$1/Dockerfile
        echo 'RUN chmod 0777 /var/www/'$1'/media/xmlconnect/original' >> ~/contaxner-dockerfiles/$1/Dockerfile
        echo 'RUN chmod 0777 /var/www/'$1'/media/xmlconnect/original/ok.gif' >> ~/contaxner-dockerfiles/$1/Dockerfile
        echo 'RUN chmod 0777 /var/www/'$1'/media/xmlconnect/system' >> ~/contaxner-dockerfiles/$1/Dockerfile
        echo 'RUN chmod 0777 /var/www/'$1'/media/xmlconnect/system/ok.gif' >> ~/contaxner-dockerfiles/$1/Dockerfile
        echo 'RUN chmod 0777 /var/www/'$1'/media/dhl' >> ~/contaxner-dockerfiles/$1/Dockerfile
        echo 'RUN chmod 0777 /var/www/'$1'/media/dhl/logo.jpg' >> ~/contaxner-dockerfiles/$1/Dockerfile
        echo 'RUN chmod 0777 /var/www/'$1'/media/customer' >> ~/contaxner-dockerfiles/$1/Dockerfile
        echo 'RUN chmod 0777 /var/www/'$1'/media/downloadable' >> ~/contaxner-dockerfiles/$1/Dockerfile
    fi


    #And Start the services

    echo 'CMD service mysql start; php5-fpm; nginx -c /etc/nginx/nginx.conf' >> ~/contaxner-dockerfiles/$1/Dockerfile

    [ -f $MENU_OUTPUT ] && rm $MENU_OUTPUT

    [ -f $MENU_INPUT ] && rm $MENU_INPUT

    ### DOCKER FILE GENERATED ####

    #Now we'll create our host container from the Dockerfile

    #First we need to add runtime variables to start and build scripts.


    cd ~/contaxner-dockerfiles/$1/

    sed -i -e "s/DOMAIN/$1/g" build.sh

    sed -i -e "s/DOMAIN/$1/g" start.sh

    sed -i -e "s/DOMAIN/$1/g" ssh-login.sh

    sed -i -e "s/PORT/$FREE_PORT/g" build.sh

    sed -i -e "s/PORT/$FREE_PORT/g" start.sh

    sed -i "s#ROOT#\/data\/www\/$1#g" build.sh

    sed -i "s#ROOT#\/data\/www\/$1#g" start.sh


    echo 'CMD ["/sbin/my_init", "--quiet"]' >> ~/contaxner-dockerfiles/$1/Dockerfile

    #Build the container

    /bin/bash build.sh

    #Run the container!

    /bin/bash start.sh
    echo -e "Bitti ya la!"
    exit
}

check_sys(){

    if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

    if ( [[ "$1" =~ $PATTERN ]] && [[ "$2" =~ $PATTERN ]] ); then

        add_new_domain $1 $2

    else

        dialog  --screen-center --infobox "Invalid domainname or alias" 10 30 ; sleep 3
        exit

    fi
    exit
}

check_sys $1 $2
