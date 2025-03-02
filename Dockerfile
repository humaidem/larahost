# Use Alpine as the base image
ARG OS_IMAGE=alpine:3.20
FROM $OS_IMAGE AS needs-squashing

LABEL maintainer="Humaid Al Mansoori"

ARG PHP_VERSION=82
ENV ALPINE_FRONTEND=noninteractive \
    PHP_VERSION=$PHP_VERSION \
    PUID=1000 \
    GUID=1000 \
    TZ=UTC

# Install dependencies, bash, Node.js, npm, PHP, and clean up to reduce image size
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    tzdata \
    gnupg \
    curl \
    ca-certificates \
    nano \
    zip \
    unzip \
    git \
    sqlite \
    mysql-client \
    su-exec \
    nodejs \
    gcompat \
    bash \
    libcap \
    libpng \
    librsvg \
    runit \
    nginx \
    envsubst \
    npm \
    supervisor \
    ffmpeg \
    icu \
    icu-dev \
    icu-libs \
    icu-data \
    icu-data-full \
    php$PHP_VERSION \
    php$PHP_VERSION-dev \
    php$PHP_VERSION-common \
    php$PHP_VERSION-fpm \
    php$PHP_VERSION-pdo \
    php$PHP_VERSION-opcache \
    php$PHP_VERSION-zip \
    php$PHP_VERSION-gd \
    php$PHP_VERSION-phar \
    php$PHP_VERSION-iconv \
    php$PHP_VERSION-cli \
    php$PHP_VERSION-curl \
    php$PHP_VERSION-openssl \
    php$PHP_VERSION-mbstring \
    php$PHP_VERSION-tokenizer \
    php$PHP_VERSION-fileinfo \
    php$PHP_VERSION-json \
    php$PHP_VERSION-xml \
    php$PHP_VERSION-xmlwriter \
    php$PHP_VERSION-xmlreader \
    php$PHP_VERSION-exif \
    php$PHP_VERSION-simplexml \
    php$PHP_VERSION-dom \
    php$PHP_VERSION-bcmath \
    php$PHP_VERSION-ldap \
    php$PHP_VERSION-intl \
    php$PHP_VERSION-soap \
    php$PHP_VERSION-imap \
    php$PHP_VERSION-posix \
    php$PHP_VERSION-pdo_mysql \
    php$PHP_VERSION-pdo_sqlite \
    php$PHP_VERSION-pdo_pgsql \
    php$PHP_VERSION-pecl-redis \
    php$PHP_VERSION-pecl-imagick \
    php$PHP_VERSION-pecl-swoole \
    php$PHP_VERSION-pecl-igbinary \
    php$PHP_VERSION-pecl-pcov \
    php$PHP_VERSION-pcntl \
    php$PHP_VERSION-pear \
    php$PHP_VERSION-mysqli \
    php$PHP_VERSION-ctype \
    php$PHP_VERSION-sodium \
    php$PHP_VERSION-gmp && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk && \
    apk add --no-cache --force-overwrite glibc-2.28-r0.apk && \
    rm glibc-2.28-r0.apk && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/* && \
    find /usr/share/man /usr/share/doc /usr/share/info /usr/share/licenses -type f | xargs rm -rf && \
    find / -type f -name "*.apk-new" -exec rm {} \;

# Symlink PHP binaries
RUN [ ! -e /usr/bin/php ] && ln -s /usr/bin/php$PHP_VERSION /usr/bin/php || echo "/usr/bin/php already exists, skipping symlink creation"
RUN [ ! -e /usr/bin/phpize ] && ln -s /usr/bin/phpize$PHP_VERSION /usr/bin/phpize || echo "/usr/bin/phpize already exists, skipping symlink creation"
RUN [ ! -e /usr/bin/php-config ] && ln -s /usr/bin/php-config$PHP_VERSION /usr/bin/php-config || echo "/usr/bin/php-config already exists, skipping symlink creation"
RUN [ ! -e /usr/bin/php-fpm ] && ln -s /usr/sbin/php-fpm$PHP_VERSION /usr/bin/php-fpm || echo "/usr/bin/php-fpm already exists, skipping symlink creation"
RUN [ ! -e /usr/bin/pear ] && ln -s /usr/bin/pear$PHP_VERSION /usr/bin/pear || echo "/usr/bin/pear already exists, skipping symlink creation"
RUN [ ! -e /usr/bin/peardev ] && ln -s /usr/bin/peardev$PHP_VERSION /usr/bin/peardev || echo "/usr/bin/peardev already exists, skipping symlink creation"
RUN [ ! -e /usr/bin/pecl ] && ln -s /usr/bin/pecl$PHP_VERSION /usr/bin/pecl || echo "/usr/bin/pecl already exists, skipping symlink creation"


# Install Composer
RUN curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash && \
      mv $HOME/.bun/bin/bun /usr/local/bin/bun && \
      chmod +x /usr/local/bin/bun && \
      rm -rf /root/.bun /root/.cache /tmp/*

# Copy entrypoint script and set permissions
COPY rootfs/start-container /usr/local/bin/start-container
RUN chmod 755 /usr/local/bin/start-container

# Copy additional runit configurations
COPY rootfs/runit /etc/sv
COPY rootfs/process_config.sh /usr/local/bin/process_config.sh

# Create the docker user and group
RUN addgroup -g $GUID docker && \
    adduser -D -u $PUID -G docker -s /bin/bash docker

RUN mkdir -p /run/php && \
    mkdir -p /home/docker/www/public && \
    echo "<?php phpinfo();" > /home/docker/www/public/index.php && \
    echo "export PATH=~/.composer/vendor/bin:\$PATH" > /home/docker/.bashrc && \
    chown -Rf docker:docker /home/docker

USER docker
RUN composer global require laravel/installer
RUN source /home/docker/.bashrc
USER root

# Start from a clean state
FROM $OS_IMAGE
COPY --from=needs-squashing / /

# Set environment variables
ENV TZ=UTC \
    PUID=1000 \
    GUID=1000

# Set working directory
WORKDIR /home/docker/www

# Expose the necessary port
EXPOSE 80

# Define the entrypoint
ENTRYPOINT ["start-container"]
