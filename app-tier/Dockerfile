# app-tier/Dockerfile — add new PHP files
FROM php:8.2-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
    libonig-dev && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install mysqli pdo pdo_mysql

RUN a2enmod rewrite

# Copy ALL PHP files
COPY submit.php    /var/www/html/submit.php
COPY login.php     /var/www/html/login.php
COPY register.php  /var/www/html/register.php
COPY dashboard.php /var/www/html/dashboard.php
COPY logout.php    /var/www/html/logout.php

RUN chown -R www-data:www-data /var/www/html \
    && chmod 644 /var/www/html/*.php

EXPOSE 80