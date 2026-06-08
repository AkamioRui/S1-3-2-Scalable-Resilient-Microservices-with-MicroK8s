FROM php:8.5-apache

WORKDIR /var/www/html
COPY ./hello.php ./
COPY ./stress.php ./


CMD [ "apache2ctl", "-D", "FOREGROUND" ]
