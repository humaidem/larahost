# Define the base image
ARG DOCKER_IMAGE
FROM $DOCKER_IMAGE AS needs-squashing

LABEL maintainer="Humaid Al Mansoori"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    NODE_VERSION=20 \
    PUID=1337 \
    PGID=1337

# Install dependencies, clean up to reduce image size
RUN apt update -y && apt install -y gnupg curl && \
    apt upgrade -y && \
    apt -y autoremove && apt -y purge && apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add NodeSource GPG key and repository
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt update -y

# Install additional packages and ensure security updates
RUN apt install -y \
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
    wget \
    lsb-release && \
    apt upgrade -y && \
    apt -y autoremove && apt -y purge && apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

# Create user and setup directories
RUN groupadd --force -g $PGID docker && \
    useradd -ms /bin/bash --no-user-group -g $PGID -u $PUID docker && \
    mkdir -p /home/docker/www/public && \
    echo "humaid/laraHost:base" > /home/docker/www/public/index.html && \
    chown -R docker:docker /home/docker

# Copy and setup service scripts
COPY rootfs/base/sv /etc/sv
RUN find /etc/sv/*/run -type f -exec chmod 755 {} \;

# Setup nginx configuration
RUN mkdir -p /etc/nginx/sites-available-conf

# Setup supervisor configuration
RUN mkdir /etc/supervisor.d

# Copy entrypoint script and set permissions
COPY rootfs/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh
RUN chmod 755 /usr/bin/docker-entrypoint.sh

# Start from a clean state
FROM scratch
COPY --from=needs-squashing / /

# Set environment variables
ENV TZ=UTC \
    NGINX_CLIENT_MAX_BODY_SIZE=1M \
    NGINX_PUBLIC_PATH=/home/docker/www/public \
    CRON_ENABLED=true \
    LARAVEL_BASE_PATH=/home/docker/www

# Set working directory
WORKDIR /home/docker/www

# Expose the necessary port
EXPOSE 80

# Define the entrypoint
CMD ["/usr/bin/docker-entrypoint.sh"]
