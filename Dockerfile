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
&&  rm -rf /var/www/theme-curatescape-echo.zip /var/www/html/themes/theme-curatescape-echo-2.0.7

# Upstream theme (as of 2.0.7) only ships a de_DE translation catalog; add
# Spanish so the public-facing site is fully translated. This site's Omeka
# locale is "es" (Omeka core only ships es.mo/es_CO.mo, not es_ES.mo), so the
# catalog filename must be es.mo for add_translation_source() to find it; the
# es_ES.mo copy is kept too in case the locale is ever switched to es_ES.
COPY ./translations/curatescape-echo/es.po ./translations/curatescape-echo/es.mo ./translations/curatescape-echo/es_ES.po ./translations/curatescape-echo/es_ES.mo /var/www/html/themes/curatescape-echo/languages/

# Curatescape 2.0+ themes require the standalone Curatescape plugin, which as of
# 1.0.x absorbs CuratescapeJSON, CuratescapeAdminHelper, TourBuilder and SuperRss
# (installing those alongside it causes the plugin to flag them as deprecated/conflicting)
RUN curl -J -L -s -k \
    'https://github.com/CPHDH/Curatescape/archive/refs/tags/1.0.12.zip' \
    -o /var/www/Curatescape.zip \
&&  unzip -q /var/www/Curatescape.zip -d /var/www/html/plugins/ \
&&  mv /var/www/html/plugins/Curatescape-1.0.12 /var/www/html/plugins/Curatescape \
&&  rm /var/www/Curatescape.zip

# Same locale-filename gap as the theme above: the plugin ships es_ES.mo but
# this site's Omeka locale is "es", so add an es.mo copy of the same catalog.
COPY ./translations/curatescape-plugin/es.po ./translations/curatescape-plugin/es.mo /var/www/html/plugins/Curatescape/languages/

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
COPY ./config.ini /var/www/html/application/config/config.ini
COPY ./.htaccess /var/www/html/.htaccess
COPY ./imagemagick-policy.xml /etc/ImageMagick/policy.xml

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
