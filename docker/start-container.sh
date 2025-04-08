#!/bin/sh
set -e

export DOLLAR="$"

export PUID="${PUID:-1000}"
export GUID="${GUID:-1000}"

# Function to update group ID if it doesn't match the provided GUID
update_group() {
    if [ "$(getent group docker | cut -d: -f3)" != "$GUID" ]; then
        echo "Updating group ID to $GUID"
        groupmod -g "$GUID" docker
        find /home/docker -maxdepth 1 -exec chown docker {} +
    fi
}

# Function to update user ID if it doesn't match the provided UID
update_user() {
    if [ "$(id -u docker)" != "$PUID" ]; then
        echo "Updating user ID to $PUID"
        usermod -u "$PUID" -g "$GUID" docker
        find /home/docker -maxdepth 1 -exec chown :docker {} +
    fi
}

# Update group and user IDs
update_group
update_user

# nginx
/docker/nginx/entry.sh
# pma
/docker/pma/entry.sh
# horizon
/docker/horizon/entry.sh
# mail
/docker/mail/entry.sh
# reverb
/docker/reverb/entry.sh
# php
/docker/php/entry.sh

# crontab
if [ "$SCHEDULE_ENABLE" = "true" ]; then
  # Start cron
  service cron start
fi

#chmod -R ugo+rw /.composer

if [ $# -gt 0 ]; then
    exec "$@"
else
    envsubst < /docker/supervisord.conf > /etc/supervisor/conf.d/supervisord.conf
    exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
fi