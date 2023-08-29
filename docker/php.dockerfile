FROM php:8.2-fpm-alpine3.17

# environment arguments
ARG UID
ARG GID
ARG USER

ENV UID=${UID}
ENV GID=${GID}
ENV USER=${USER}

# Dialout group in alpine linux conflicts with MacOS staff group's gid, whis is 20. So we remove it.
RUN delgroup dialout

# Creating user and group
RUN addgroup -g ${GID} --system ${USER}
RUN adduser -G ${USER} --system -D -s /bin/sh -u ${UID} ${USER}
RUN chown -R ${USER}:${USER} /var/www/html

# Modify php fpm configuration to use the new user's priviledges.
RUN sed -i "s/user = www-data/user = '${USER}'/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/group = www-data/group = '${USER}'/g" /usr/local/etc/php-fpm.d/www.conf
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

# Install PostgreSQL
RUN apk add --no-cache postgresql-dev
RUN docker-php-ext-install pdo_pgsql pgsql pdo

RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo_pgsql pgsql
# Install intl extension
RUN docker-php-ext-install intl

# Install GD
RUN apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev zlib-dev libwebp-dev
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install gd

# Install ZIP
RUN apk add --no-cache libzip-dev
RUN docker-php-ext-install zip

RUN chown 777 -R /var/www/html/

# Installing redis extension
RUN mkdir -p /usr/src/php/ext/redis \
    && curl -fsSL https://github.com/phpredis/phpredis/archive/5.3.4.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 \
    && echo 'redis' >> /usr/src/php-available-exts \
    && docker-php-ext-install redis

CMD ["php-fpm", "-y", "/usr/local/etc/php-fpm.conf", "-R"]
