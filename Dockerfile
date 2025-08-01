# main image
FROM php:8.3-apache

# installing dependencies
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    libfreetype6-dev \
    libicu-dev \
    libgmp-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxpm-dev \
    libzip-dev \
    unzip \
    zlib1g-dev

# configuring php extension
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-configure intl

# installing php extension
RUN docker-php-ext-install bcmath calendar exif gd gmp intl mysqli pdo pdo_mysql zip

# installing composer
COPY --from=composer:2.7 /usr/bin/composer /usr/local/bin/composer

# installing node js
COPY --from=node:22.9 /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node:22.9 /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# installing global node dependencies
RUN npm install -g npx
RUN npm install -g laravel-echo-server

# arguments with defaults
ARG container_project_path=/var/www/html
ARG uid=1000
ARG user=www-data

# setting work directory
WORKDIR ${container_project_path}

# create user only if it doesn't exist
RUN id -u ${user} 2>/dev/null || useradd -G www-data,root -u ${uid} -d /home/${user} ${user}

# composer folder permissions
RUN mkdir -p /home/${user}/.composer && \
    chown -R ${user}:${user} /home/${user}

# setting apache
COPY ./.configs/apache.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# setting up project permissions
RUN chmod -R 775 ${container_project_path} && \
    chown -R ${user}:www-data ${container_project_path}

# change user
USER ${user}
