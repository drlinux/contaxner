#!/bin/sh
export HOME="/root"
exec /etc/init.d/nginx start > /dev/null 2>&1
exec /etc/init.d/php5-fpm start > /dev/null 2>&1
exec /etc/init.d/mysql start > /dev/null 2>&1
