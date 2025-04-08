#!/bin/sh
set -e

mkdir -p /etc/nginx/http.default.d

envsubst < /docker/nginx/nginx.conf > /etc/nginx/nginx.conf
envsubst < /docker/nginx/supervisor.nginx.conf > /etc/supervisor/conf.d/nginx.conf

