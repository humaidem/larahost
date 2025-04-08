#!/bin/sh
set -e

if [ "$HORIZON_ENABLE" = "true" ]; then
  printf "Horizon: enabled ...\n"
  envsubst < /docker/horizon/nginx.horizon.conf > /etc/supervisor/conf.d/horizon.conf
fi