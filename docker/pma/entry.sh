#!/bin/sh
set -e

if [ "$PMA_ENABLE" = "true" ]; then
  printf "Nginx: PMA reverse proxy enabled ...\n"
  envsubst < /docker/pma/nginx.pma.conf > /etc/nginx/http.default.d/pma.conf
fi