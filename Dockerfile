ARG DOCKER_IMAGE

FROM $DOCKER_IMAGE AS needs-squashing

LABEL maintainer="Humaid Al Mansoori"

ARG NODE_VERSION=20
ARG POSTGRES_VERSION=15
ARG PHP_VERSION
ENV PHP_VERSION=$PHP_VERSION

# docker user uid and gid
ENV PUID=1337
ENV PGID=1337
# create user
RUN groupadd --force -g $PGID docker
RUN useradd -ms /bin/bash --no-user-group -g $PGID -u $PUID docker
RUN mkdir -p /home/docker/www/public && echo "<?php phpinfo();" > /home/docker/www/public/index.php
WORKDIR /home/docker/www


ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


RUN mkdir -p /etc/apt/keyrings
RUN apt update -y
RUN apt install -y curl gnupg
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null
RUN echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
RUN curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/keyrings/pgdg.gpg >/dev/null
RUN echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt update -y
RUN exit
RUN apt update -y
RUN apt upgrade -y


# base packages
RUN apt install -y \
    runit \
    gnupg \
    ca-certificates \
    zip \
    unzip \
    git \
    supervisor \
    sqlite3 \
    libcap2-bin \
    libpng-dev \
    python2 \
    dnsutils \
    librsvg2-bin \
    gettext-base \
    nginx \
    nano \
    cron \
    ffmpeg \
    unixodbc \
    unixodbc-dev \
    libgssapi-krb5-2 \
    libtool \
    nodejs \
    mysql-client \
    postgresql-client-$POSTGRES_VERSION


RUN ACCEPT_EULA=Y apt install -y msodbcsql18

RUN apt install -y \
    php$PHP_VERSION-fpm \
    php$PHP_VERSION-cli \
    php$PHP_VERSION-dev \
    php$PHP_VERSION-pgsql \
    php$PHP_VERSION-sqlite3 \
    php$PHP_VERSION-gd \
    php$PHP_VERSION-imagick \
    php$PHP_VERSION-curl \
    php$PHP_VERSION-imap \
    php$PHP_VERSION-mysql \
    php$PHP_VERSION-mbstring \
    php$PHP_VERSION-xml \
    php$PHP_VERSION-zip \
    php$PHP_VERSION-bcmath \
    php$PHP_VERSION-soap \
    php$PHP_VERSION-intl \
    php$PHP_VERSION-readline \
    php$PHP_VERSION-ldap \
    php$PHP_VERSION-msgpack \
    php$PHP_VERSION-igbinary \
    php$PHP_VERSION-redis \
    php$PHP_VERSION-swoole \
    php$PHP_VERSION-memcached


RUN curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer
RUN pecl install sqlsrv pdo_sqlsrv
RUN printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/$PHP_VERSION/mods-available/sqlsrv.ini
RUN printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/$PHP_VERSION/mods-available/pdo_sqlsrv.ini
RUN phpenmod -v $PHP_VERSION sqlsrv pdo_sqlsrv


RUN apt remove -y gnupg gcc g++ autoconf make cpp
RUN apt -y autoremove \
    && apt -y purge \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*





RUN setcap "cap_net_bind_service=+ep" /usr/bin/php$PHP_VERSION
#
#
###php
##COPY rootfs/empty.sh /usr/bin/entrypoints/php-entrypoint.sh
##RUN chmod 755 /usr/bin/entrypoints/php-entrypoint.sh
##
### cron tab
##COPY rootfs/cron/docker /var/spool/cron/crontabs/docker
##COPY rootfs/cron/cron-entrypoint.sh /usr/bin/entrypoints/cron-entrypoint.sh
##RUN chmod 755 /usr/bin/entrypoints/cron-entrypoint.sh
##
### nginx
##RUN mkdir -p /etc/nginx/conf.base.d
##COPY rootfs/nginx/index.php /home/docker/www/public/index.php
##COPY rootfs/nginx/nginx.conf.nginx /etc/nginx/nginx.conf.nginx
##COPY rootfs/nginx/conf.base.d /etc/nginx/conf.base.d
##COPY rootfs/nginx/nginx-entrypoint.sh /usr/bin/entrypoints/nginx-entrypoint.sh
##RUN chmod 755 /usr/bin/entrypoints/nginx-entrypoint.sh
##
### chown docker folder ownership
##RUN chown -R docker:docker /home/docker
##
### supervisor
##COPY rootfs/supervisor/conf.studs/horizon.conf /etc/supervisor/conf.studs/horizon.conf
##COPY rootfs/supervisor/conf.studs/laravel-workers.conf /etc/supervisor/conf.studs/laravel-workers.conf
##COPY rootfs/supervisor/conf.studs/octane.conf /etc/supervisor/conf.studs/octane.conf
##COPY rootfs/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
##COPY rootfs/supervisor/supervisor-entrypoint.sh /usr/bin/entrypoints/supervisor-entrypoint.sh
##RUN chmod 755 /usr/bin/entrypoints/supervisor-entrypoint.sh
##
### ssl
##COPY rootfs/ssl/openssl.cnf /etc/ssl/openssl.cnf
##
### Copy local folder to docker image
##COPY ../rootfs/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh
##RUN chmod 755 /usr/bin/docker-entrypoint.sh
#
#
#
COPY rootfs/sv /etc/sv

# docker entry point
COPY rootfs/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh
RUN chmod 755 /usr/bin/docker-entrypoint.sh
RUN mkdir /etc/supervisor.d
RUN find /etc/sv/*/run -type f -print -exec chmod 755 {} \;
RUN chown -R docker:docker /home/docker

FROM scratch
COPY --from=needs-squashing / /
ARG PHP_VERSION
ENV PHP_VERSION=$PHP_VERSION
ENV TZ=UTC
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
WORKDIR /home/docker/www
EXPOSE 80
CMD [ "/usr/bin/docker-entrypoint.sh" ]
