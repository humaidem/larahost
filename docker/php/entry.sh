#!/bin/sh
set -e

# custom php settings
envsubst < /docker/php/fpm.custom.ini > /etc/php/$PHP_VERSION/fpm/conf.d/custom.ini
envsubst < /docker/php/fpm.www.conf > /etc/php/$PHP_VERSION/fpm/pool.d/www.conf

if [ "$PHP_FPM_ENABLE" = "true" ]; then
  printf "Nginx: enabling PHP-FPM ($PHP_VERSION) ...\n"
  envsubst < /docker/php/nginx.fpm.conf > /etc/nginx/sites-available/default
  envsubst < /docker/php/supervisor.php-fpm.conf > /etc/supervisor/conf.d/php-fpm.conf
fi