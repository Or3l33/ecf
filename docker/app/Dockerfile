# Image applicative : Apache + PHP 8.2 + extensions PHP + Composer + client MySQL
FROM php:8.2-apache

# Dépendances système et extensions PHP (gd, zip, pdo_mysql, mysqli)
RUN apt-get update && apt-get install -y --no-install-recommends \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libzip-dev \
        unzip \
        git \
        default-mysql-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql mysqli gd zip \
    && rm -rf /var/lib/apt/lists/*

# Composer copié depuis son image officielle (version majeure 2 figée)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Version de l'application, passée au build : docker compose build --build-arg APP_VERSION=v2
ARG APP_VERSION=v1
ENV APP_VERSION=${APP_VERSION}

# Code de l'application
COPY src/ /var/www/html/

EXPOSE 80
