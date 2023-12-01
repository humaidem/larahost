ARG ALPINE_VERSION
FROM alpine:$ALPINE_VERSION
ARG PHP_VERSION
ENV PHP_VERSION=$PHP_VERSION
ARG ALPINE_VERSION
ENV ALPINE_VERSION=$ALPINE_VERSION
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# docker user uid and gid
ENV PUID=1337
ENV PGID=1337

ENV MAKEFLAGS=" -j 8"
# create user
RUN addgroup -g $PGID docker
RUN adduser -D -h /home/docker -G docker -u $PUID docker
RUN mkdir -p /home/docker/www/public

RUN apk --no-cache update \
&& apk --no-cache upgrade \
&& apk --no-cache add --update \
    openssh \
    runit \
    nginx \
    shadow \
    gettext \
    busybox-suid \
    curl \
    wget \
    nano \
    libavif \
    icu \
    icu-data-full \
    icu-libs \
    mysql-client \
    php$PHP_VERSION-dev \
    php$PHP_VERSION-cli \
    php$PHP_VERSION-fpm \
    php$PHP_VERSION-pgsql \
    php$PHP_VERSION-sqlite3 \
    php$PHP_VERSION-gd \
    php$PHP_VERSION-pecl-imagick \
    php$PHP_VERSION-curl \
    php$PHP_VERSION-imap \
    php$PHP_VERSION-mysqli \
    php$PHP_VERSION-pdo_mysql \
    php$PHP_VERSION-mbstring \
    php$PHP_VERSION-xml \
    php$PHP_VERSION-zip \
    php$PHP_VERSION-bcmath \
    php$PHP_VERSION-soap \
    php$PHP_VERSION-intl \
    php$PHP_VERSION-ldap \
    php$PHP_VERSION-pear \
    php$PHP_VERSION-pdo \
    php$PHP_VERSION-openssl \
    php$PHP_VERSION-redis \
    php$PHP_VERSION-phar \
    php$PHP_VERSION-pecl-igbinary \
    php$PHP_VERSION-pecl-msgpack \
    php$PHP_VERSION-pecl-swoole \
    php$PHP_VERSION-pecl-memcached \
    php$PHP_VERSION-tokenizer \
    php$PHP_VERSION-fileinfo \
    php$PHP_VERSION-dom \
    php$PHP_VERSION-exif \
    php$PHP_VERSION-xmlwriter \
    php$PHP_VERSION-pcntl \
    php$PHP_VERSION-posix \
    php$PHP_VERSION-simplexml \
    php$PHP_VERSION-iconv \
    && ln -sf /usr/bin/php$PHP_VERSION /usr/bin/php \
    && ln -s /usr/sbin/php-fpm$PHP_VERSION /usr/bin/php-fpm \
    && curl -sS https://getcomposer.org/installer | php$PHP_VERSION -- --install-dir=/usr/bin --filename=composer \
    && apk --no-cache add --update --repository https://dl-cdn.alpinelinux.org/alpine/v3.18/main supervisor py3-setuptools=67.7.2-r0 \
    && if [ $(uname -m) = "aarch64" ] ; then \
               curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/msodbcsql18_18.3.2.1-1_arm64.apk; \
               apk add --allow-untrusted msodbcsql18_18.3.2.1-1_arm64.apk; \
               rm -f msodbcsql18_18.3.2.1-1_arm64.apk; \
           else \
               curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/msodbcsql18_18.3.2.1-1_amd64.apk; \
               apk add --allow-untrusted msodbcsql18_18.3.2.1-1_amd64.apk; \
               rm -f msodbcsql18_18.3.2.1-1_amd64.apk; \
           fi \
    && apk --no-cache add --update autoconf gcc musl-dev make unixodbc-dev build-base \
    && pecl install sqlsrv \
    && pecl install pdo_sqlsrv \
    && echo extension=pdo_sqlsrv.so >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/10_pdo_sqlsrv.ini \
    && echo extension=sqlsrv.so >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/20_sqlsrv.ini \
    && apk del autoconf gcc musl-dev make unixodbc-dev build-base


COPY rootfs/sv /etc/sv
RUN mkdir -p /home/docker/www/public && echo "<?php phpinfo();" > /home/docker/www/public/index.php
# docker entry point
COPY rootfs/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh
RUN chmod 755 /usr/bin/docker-entrypoint.sh
RUN mkdir /etc/supervisor.d
RUN find /etc/sv/*/run -type f -print -exec chmod 755 {} \;
RUN chown -R docker:docker /home/docker


WORKDIR /home/docker/www

# horizon
ENV LARAHOST_HORIZON_ENABLED=false
ENV LARAHOST_HORIZON_ENABLE_LOG=false
# octane
ENV LARAHOST_OCTANE_ENABLED=false
ENV LARAHOST_OCTANE_WORKERS=4
ENV LARAHOST_OCTANE_TASK_WORKERS=6
ENV LARAHOST_OCTANE_ENABLE_LOG=false
# queue
ENV LARAHOST_QUEUE_ENABLED=false
ENV LARAHOST_QUEUE_NAMES='default:1'
ENV LARAHOST_QUEUE_ENABLE_LOG=false
# nginx
ENV LARAHOST_NGINX_CLIENT_MAX_BODY_SIZE=1M
#php
ENV LARAHOST_PHP_ALLOW_URL_FOPEN=Off
ENV LARAHOST_PHP_DISPLAY_ERRORS=Off
ENV LARAHOST_PHP_FILE_UPLOADS=On
ENV LARAHOST_PHP_MAX_EXECUTION_TIME=30
ENV LARAHOST_PHP_MAX_INPUT_TIME=300
ENV LARAHOST_PHP_MAX_INPUT_VARS=1000
ENV LARAHOST_PHP_MEMORY_LIMIT=128M
ENV LARAHOST_PHP_POST_MAX_SIZE=1M
ENV LARAHOST_PHP_UPLOAD_MAX_FILESIZE=1M
ENV LARAHOST_PHP_ZLIB_OUTPUT_COMPRESSION=On
ENV LARAHOST_PHP_CLEAR_ENV=no
ENV LARAHOST_PHP_CA_CERT=""
EXPOSE 80
CMD [ "/usr/bin/docker-entrypoint.sh" ]

