FROM php:8.4-apache

RUN a2enmod rewrite

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && apt-get -qq -y --no-install-recommends install \
    curl \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libjpeg-dev \
    libmemcached-dev \
    zlib1g-dev \
    imagemagick

# install the PHP extensions we need
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) \
    pdo pdo_mysql mysqli gd

RUN docker-php-ext-install exif && \
    docker-php-ext-enable exif

RUN curl -J -L -s -k \
    'https://github.com/omeka/Omeka/releases/download/v3.2.1/omeka-3.2.1.zip' \
    -o /var/www/omeka.zip \
&&  unzip -q /var/www/omeka.zip -d /var/www/ \
&&  rm /var/www/omeka.zip \
&&  rm -rf /var/www/html \
&&  mv /var/www/omeka-3.2.1 /var/www/html

RUN curl -J -L -s -k \
    'https://github.com/CPHDH/theme-curatescape-echo/archive/refs/tags/2.0.7.zip' \
    -o /var/www/theme-curatescape-echo.zip \
&&  unzip -q /var/www/theme-curatescape-echo.zip -d /var/www/html/themes/ \
&&  mv /var/www/html/themes/theme-curatescape-echo-2.0.7/curatescape-echo /var/www/html/themes/curatescape-echo \
&&  rm /var/www/theme-curatescape-echo.zip

# Curatescape 2.0+ themes require the standalone Curatescape plugin, which as of
# 1.0.x absorbs CuratescapeJSON, CuratescapeAdminHelper, TourBuilder and SuperRss
# (installing those alongside it causes the plugin to flag them as deprecated/conflicting)
RUN curl -J -L -s -k \
    'https://github.com/CPHDH/Curatescape/archive/refs/tags/1.0.12.zip' \
    -o /var/www/Curatescape.zip \
&&  unzip -q /var/www/Curatescape.zip -d /var/www/html/plugins/ \
&&  mv /var/www/html/plugins/Curatescape-1.0.12 /var/www/html/plugins/Curatescape \
&&  rm /var/www/Curatescape.zip

RUN curl -J -L -s -k \
    'https://github.com/omeka/plugin-Geolocation/archive/refs/heads/master.zip' \
    -o /var/www/plugin-Geolocation-master.zip \
&&  unzip -q /var/www/plugin-Geolocation-master.zip -d /var/www/html/plugins/ \
&&  mv /var/www/html/plugins/plugin-Geolocation-master /var/www/html/plugins/Geolocation \
&&  rm /var/www/plugin-Geolocation-master.zip

RUN curl -J -L -s -k \
    'https://github.com/omeka/plugin-SimplePages/archive/refs/heads/master.zip' \
    -o /var/www/plugin-SimplePages-master.zip \
&&  unzip -o -q /var/www/plugin-SimplePages-master.zip -d /var/www/html/plugins/ \
&&  rm /var/www/plugin-SimplePages-master.zip

# SuperRss is deprecated and replaced by the Curatescape plugin (see above)

RUN curl -J -L -s -k \
    'https://github.com/ebellempire/MoreUserRoles/archive/master.zip' \
    -o /var/www/MoreUserRoles-master.zip \
&&  unzip -q /var/www/MoreUserRoles-master.zip -d /var/www/html/plugins/ \
&&  mv /var/www/html/plugins/MoreUserRoles-master /var/www/html/plugins/MoreUserRoles \
&&  rm /var/www/MoreUserRoles-master.zip


RUN  chown -R www-data:www-data /var/www/html

COPY ./db.ini /var/www/html/db.ini
COPY ./.htaccess /var/www/html/.htaccess
COPY ./imagemagick-policy.xml /etc/ImageMagick/policy.xml

VOLUME /var/www/html

CMD ["apache2-foreground"]
