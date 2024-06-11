#!/bin/bash

set -o pipefail

# Adjust permissions for run scripts
find /etc/sv/*/run -type f -exec chmod 755 {} +

# Set default values for PUID and PGID
: "${PUID:=1000}"
: "${PGID:=1000}"

# Update user ID if necessary
if [ "$PUID" -ne 1000 ]; then
    printf "Switching ubuntu user id to %d!\n" "$PUID"
    usermod -u "$PUID" ubuntu
    printf "ubuntu user id set to %d!\n" "$PUID"
    find /home/ubuntu -maxdepth 1 -exec chown ubuntu {} +
fi

# Update group ID if necessary
if [ "$PGID" -ne 1000 ]; then
    printf "Switching ubuntu group id to %d!\n" "$PGID"
    groupmod -g "$PGID" ubuntu
    printf "ubuntu group id set to %d!\n" "$PGID"
    find /home/ubuntu -maxdepth 1 -exec chown :ubuntu {} +
fi

# Ensure .composer directory exists and set permissions
if [ ! -d /home/ubuntu/.composer ]; then
    mkdir -p /home/ubuntu/.composer
fi

chmod -R ugo+rw /home/ubuntu/.composer

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

    update-ca-certificates --fresh

    printf "runit started...\n"
    tail -f /dev/null
fi
