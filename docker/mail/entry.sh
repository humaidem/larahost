#!/bin/sh
set -e

if [ "$MAIL_ENABLE" = "true" ]; then
  printf "Nginx: Mail reverse proxy enabled ...\n"
  envsubst < /docker/mail/nginx.mail.conf > /etc/nginx/http.default.d/mail.conf
fi