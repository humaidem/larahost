#!/bin/bash


find /etc/sv/*/run -type f -print -exec chmod 755 {} \;

: "${PUID:=1337}"
: "${PGID:=1337}"

if [ "$PUID" -ne 1337 ]; then
  echo "Switching docker user id to $PUID!"
  usermod -u $PUID docker
  echo "docker user id set to $PUID!"
  find /home/docker -maxdepth 1 -exec chown docker {} \;
fi

if [ "$PGID" -ne 1337 ]; then
  echo "Switching group id to $PGID!"
  groupmod -g $PGID docker
  echo "docker group id set to $PGID!"
  find /home/docker -maxdepth 1 -exec chown :docker {} \;
fi

echo "Starting runit..."
exec runsvdir -P /etc/sv &

# Wait for runit to start
while [ ! -d "/etc/sv" ]; do
  sleep 1;
done
echo "runit started..."

tail -f /dev/null

