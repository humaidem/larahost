#!/bin/bash

set -o pipefail

# Adjust permissions for run scripts
find /etc/sv/*/run -type f -exec chmod 755 {} +

# Set default values for PUID and PGID
: "${PUID:=1337}"
: "${PGID:=1337}"

# Update user ID if necessary
if [ "$PUID" -ne 1337 ]; then
    printf "Switching docker user id to %d!\n" "$PUID"
    usermod -u "$PUID" docker
    printf "docker user id set to %d!\n" "$PUID"
    find /home/docker -maxdepth 1 -exec chown docker {} +
fi

# Update group ID if necessary
if [ "$PGID" -ne 1337 ]; then
    printf "Switching group id to %d!\n" "$PGID"
    groupmod -g "$PGID" docker
    printf "docker group id set to %d!\n" "$PGID"
    find /home/docker -maxdepth 1 -exec chown :docker {} +
fi

# Ensure .composer directory exists and set permissions
if [ ! -d /home/docker/.composer ]; then
    mkdir -p /home/docker/.composer
fi

chmod -R ugo+rw /home/docker/.composer

# Execute provided command or start runit
if [ $# -gt 0 ]; then
    exec "$@"
else
    printf "Starting runit...\n"
    exec runsvdir -P /etc/sv &

    # Wait for runit to start
    while [ ! -d "/etc/sv" ]; do
        sleep 1
    done

    printf "runit started...\n"
    tail -f /dev/null
fi
