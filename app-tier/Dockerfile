FROM php:8.2-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
    libonig-dev \
    && docker-php-ext-install mysqli pdo pdo_mysql mbstring \
    && a2enmod rewrite headers \
    && rm -rf /var/lib/apt/lists/*

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY submit.php            /var/www/html/submit.php
COPY login.php             /var/www/html/login.php
COPY register.php          /var/www/html/register.php
COPY dashboard.php         /var/www/html/dashboard.php
COPY logout.php            /var/www/html/logout.php
COPY forgot-password.php   /var/www/html/forgot-password.php

RUN chown -R www-data:www-data /var/www/html \
    && chmod 644 /var/www/html/*.php

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

EXPOSE 80
