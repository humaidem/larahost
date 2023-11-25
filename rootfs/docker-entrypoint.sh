#!/bin/sh -e

: "${LARAHOST_GID:=1337}"
: "${LARAHOST_UID:=1337}"

usermod --shell /bin/ash docker

if [ "$LARAHOST_UID" -ne 1337 ]; then
  echo "Switching docker user id to $LARAHOST_UID!"
  usermod -u $LARAHOST_UID docker
  echo "docker user id set to $LARAHOST_UID!"
  find /home/docker -maxdepth 1 -exec chown docker {} \;
fi

if [ "$LARAHOST_GID" -ne 1337 ]; then
  echo "Switching group id to $LARAHOST_GID!"
  groupmod -g $LARAHOST_GID docker
  echo "docker group id set to $LARAHOST_GID!"
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

