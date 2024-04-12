# Start from the official PHP image with Alpine
ARG DOCKER_IMAGE

FROM $DOCKER_IMAGE AS needs-squashing

LABEL maintainer="Humaid Al Mansoori"

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

ARG NODE_VERSION=20
ARG PHP_VERSION
ENV PHP_VERSION=$PHP_VERSION
ENV PUID=1337
ENV PGID=1337

RUN apt update -y && apt install -y gnupg curl

RUN mkdir -p /etc/apt/keyrings
RUN curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null
RUN echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
RUN apt update -y

RUN apt install -y \
    gnupg \
    curl \
    runit \
    ca-certificates \
    nano \
    zip \
    unzip \
    git \
    sqlite3 \
    mysql-client \
    libcap2-bin \
    libpng-dev \
    dnsutils \
    librsvg2-bin \
    gettext-base \
    nginx \
    cron \
    nodejs \
    python2 \
    supervisor \
    php$PHP_VERSION-fpm \
    php$PHP_VERSION-cli \
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
    php$PHP_VERSION-gmp && \
    apt remove -y gnupg gcc g++ autoconf make cpp && \
    apt -y autoremove \
        && apt -y purge \
        && apt clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN setcap "cap_net_bind_service=+ep" /usr/bin/php$PHP_VERSION
RUN curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# create user
RUN groupadd --force -g $PGID docker
RUN useradd -ms /bin/bash --no-user-group -g $PGID -u $PUID docker
RUN mkdir -p /home/docker/www/public && echo "<?php phpinfo();" > /home/docker/www/public/index.php
RUN chown -R docker:docker /home/docker


COPY rootfs/sv /etc/sv
RUN find /etc/sv/*/run -type f -print -exec chmod 755 {} \;

# nginx
RUN mkdir -p /etc/nginx/sites-available-conf


# supervisor
RUN mkdir /etc/supervisor.d

# entrypoint script
COPY rootfs/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh
RUN chmod 755 /usr/bin/docker-entrypoint.sh




FROM scratch
COPY --from=needs-squashing / /
ARG PHP_VERSION
ENV PHP_VERSION=$PHP_VERSION
ENV TZ=UTC

# nginx
ENV NGINX_CLIENT_MAX_BODY_SIZE=1M
ENV NGINX_PUBLIC_PATH=/home/docker/www/public

#php
ENV PHP_FPM_ENABLED=true
ENV PHP_MAX_INPUT_TIME=300
ENV PHP_UPLOAD_MAX_FILESIZE=1M
ENV PHP_POST_MAX_SIZE=1M
ENV PHP_MAX_INPUT_VARS=1000
ENV PHP_MEMORY_LIMIT=128M
ENV PHP_ZLIB_OUTPUT_COMPRESSION=On
ENV PHP_ALLOW_URL_FOPEN=Off
ENV PHP_DISPLAY_ERRORS=Off
ENV PHP_CLEAR_ENV=no
ENV PHP_FILE_UPLOADS=On
ENV PHP_MAX_EXECUTION_TIME=30

# cron
ENV CRON_ENABLED=true
ENV LARAVEL_BASE_PATH=/home/docker/www

#queue
ENV QUEUE_ENABLED=true
ENV QUEUE_NAMES='default:1'
ENV QUEUE_ENABLE_LOG=false

# set working directory
WORKDIR /home/docker/www

EXPOSE 80
CMD [ "/usr/bin/docker-entrypoint.sh" ]
