FROM node:latest AS node
FROM php:8.2-fpm
# Install all lib need
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
&& apt-get install -y locales apt-utils git libicu-dev g++ libpng-dev \
libxml2-dev libzip-dev libonig-dev libxslt-dev gconf-service libasound2 \
libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 \
libgbm1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 \
libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 \
libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libnss3 lsb-release \
xdg-utils wget libgbm-dev libxshmfence-dev \
&& apt-get clean -y && rm -rf /var/lib/apt/lists/*
# install node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
# Install php-mysql driver and others
RUN docker-php-ext-install pdo pdo_mysql gd opcache intl zip calendar dom mbstring zip gd xsl pcntl sockets
# XDebug
RUN yes | pecl install xdebug \
&& echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
&& echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini \
&& echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini \
&& echo "xdebug.idekey=XDEBUG" >> /usr/local/etc/php/conf.d/xdebug.ini \
&& echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini \
&& echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini \
&& echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/xdebug.ini
WORKDIR /workspace
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer
RUN wget https://get.symfony.com/cli/installer -O - | bash
RUN mv /root/.symfony5/bin/symfony /usr/local/bin/symfony