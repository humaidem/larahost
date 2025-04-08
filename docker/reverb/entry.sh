#!/bin/sh
set -e

if [ "$REVERB_ENABLE" = "true" ]; then
  printf "Reverb: enabled ...\n"
  envsubst < /docker/reverb/nginx.reverb.conf > /etc/nginx/http.default.d/reverb.conf
  envsubst < /docker/reverb/supervisor.reverb.conf > /etc/supervisor/conf.d/reverb.conf

fi