ARG OS_IMAGE=ubuntu:24.04
FROM ${OS_IMAGE} AS builder

LABEL maintainer="Humaid Al Mansoori"

ARG PHP_VERSION=8.0
ARG NODE_VERSION=22
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    PHP_VERSION=${PHP_VERSION}

RUN apt-get update && \
    apt-get upgrade -y && \
    mkdir -p /etc/apt/keyrings && \
    apt-get install -y --no-install-recommends \
    gnupg \
    gosu \
    curl \
    ca-certificates \
    zip \
    unzip \
    git \
    supervisor \
    sqlite3 \
    libcap2-bin \
    libpng-dev \
    python3 \
    dnsutils \
    librsvg2-bin \
    fswatch \
    ffmpeg \
    cron \
    nano \
    nginx \
    gettext \
    mysql-client && \
    # PHP repo and install
    curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xb8dc7e53946656efbce4c1dd71daeaab4ad4cab6' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu noble main" > /etc/apt/sources.list.d/ppa_ondrej_php.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    php${PHP_VERSION} \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-mongodb \
    php${PHP_VERSION}-imap \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-readline \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-msgpack \
    php${PHP_VERSION}-igbinary \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-swoole \
    php${PHP_VERSION}-memcached \
    php${PHP_VERSION}-pcov \
    php${PHP_VERSION}-imagick \
    php${PHP_VERSION}-xdebug \
    # Composer
    && curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer \
    # node/npm/bun/yarn etc ...
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    #&& echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && npm install -g pnpm \
    && npm install -g bun \
    #&& apt-get install -y yarn
    # Clean up
    && apt-get -y purge gnupg \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Final Stage
FROM ${OS_IMAGE}

# Copy entrypoint script and set permissions
RUN mkdir -p /docker \
    && chmod 755 /docker \
    && chown -R root:root /docker

COPY ./docker /docker
RUN find /docker -type f -name "*.sh" -exec chmod 755 {} +

ARG PHP_VERSION=8.0
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    PHP_VERSION=${PHP_VERSION}

COPY --from=builder / /


RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && usermod -l docker ubuntu && groupmod -n docker ubuntu && \
    mv /home/ubuntu /home/docker && \
    mkdir -p /home/docker/www

RUN mkdir -p /home/docker/www/public && \
    echo "<?php phpinfo();" > /home/docker/www/public/index.php && \
    echo "export PATH=~/.composer/vendor/bin:\$PATH" > /home/docker/.bashrc && \
    chown -Rf docker:docker /home/docker

RUN echo "* * * * * /usr/bin/php /home/docker/www/artisan schedule:run >> /home/docker/cron.log 2>&1" > /var/spool/cron/crontabs/docker \
    && chmod 600 /var/spool/cron/crontabs/docker \
    && chown docker:crontab /var/spool/cron/crontabs/docker




WORKDIR /home/docker/www

USER docker
ENV HOME=/home/docker \
    PATH="/home/docker/.config/composer/vendor/bin:$PATH"
#RUN echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> /home/docker/.bashrc
RUN mkdir -p $HOME/.config/composer && chown -R docker:docker $HOME/.config
RUN composer global require laravel/installer
USER root


ENV DOCKER_PUBLIC_ROOT=/home/docker/www/public

EXPOSE 80/tcp

CMD ["sh", "/docker/start-container.sh"]
