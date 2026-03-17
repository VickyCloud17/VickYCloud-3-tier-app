# ─────────────────────────────────────────────────────────────────
#  VickYCloud — App Tier Dockerfile
#  Base:    php:8.2-apache
#  Serves:  submit.php, login.php (proxied from web-tier nginx)
# ─────────────────────────────────────────────────────────────────

FROM php:8.2-apache

# ── System dependencies ───────────────────────────────────────
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# ── PHP extensions ────────────────────────────────────────────
RUN docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    mbstring \
    opcache

# ── PHP production config ─────────────────────────────────────
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Tune opcache for containers
RUN echo "opcache.enable=1\n\
opcache.memory_consumption=128\n\
opcache.interned_strings_buffer=8\n\
opcache.max_accelerated_files=4000\n\
opcache.revalidate_freq=60\n\
opcache.fast_shutdown=1" \
>> "$PHP_INI_DIR/conf.d/opcache.ini"

# ── Apache: enable mod_rewrite ────────────────────────────────
RUN a2enmod rewrite headers

# ── Apache security headers ───────────────────────────────────
RUN echo "ServerTokens Prod\nServerSignature Off" \
    >> /etc/apache2/conf-enabled/security.conf

# ── Copy application files ────────────────────────────────────
COPY submit.php   /var/www/html/submit.php
COPY login.php    /var/www/html/login.php

# ── File permissions ──────────────────────────────────────────
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod 644 /var/www/html/*.php

# ── Health check ──────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/submit.php || exit 1

EXPOSE 80