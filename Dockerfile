ARG PHP_VERSION=8.3
ARG COMPOSER_VERSION=2

FROM composer:${COMPOSER_VERSION} AS composer-bin

FROM php:${PHP_VERSION}-fpm-alpine

ARG PHPREDIS_VERSION=6.3.0
ARG IMAGICK_VERSION=3.8.1

RUN set -eux; \
    apk add --no-cache \
        bash \
        curl \
        fcgi \
        freetype \
        git \
        icu \
        imagemagick \
        libjpeg-turbo \
        libpng \
        libwebp \
        libzip \
        oniguruma \
        unzip; \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        freetype-dev \
        icu-dev \
        imagemagick-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libzip-dev \
        oniguruma-dev; \
    docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp; \
    docker-php-ext-install -j"$(nproc)" \
        bcmath \
        exif \
        gd \
        intl \
        mbstring \
        mysqli \
        opcache \
        pdo_mysql \
        zip; \
    pecl install redis-${PHPREDIS_VERSION} imagick-${IMAGICK_VERSION}; \
    docker-php-ext-enable opcache imagick redis; \
    php -r 'foreach (["bcmath","exif","gd","intl","mbstring","mysqli","pdo_mysql","zip","imagick","redis"] as $ext) { if (!extension_loaded($ext)) { fwrite(STDERR, "missing extension: {$ext}\\n"); exit(1); } } if (!extension_loaded("Zend OPcache")) { fwrite(STDERR, "missing extension: Zend OPcache\\n"); exit(1); }'; \
    apk del .build-deps; \
    rm -rf /tmp/pear ~/.pearrc

COPY --from=composer-bin /usr/bin/composer /usr/local/bin/composer
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh; \
    touch /usr/local/etc/php/conf.d/zzz-env.ini \
          /usr/local/etc/php-fpm.d/www.conf; \
    chown www-data:www-data \
          /usr/local/etc/php/conf.d/zzz-env.ini \
          /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html
EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 | grep -q "pong" || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
