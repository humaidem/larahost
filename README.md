> ***Docker Image under-development***

# Laravel Host docker

Larahost provide ready to go production environment for Laravel applications.

## Setup

> ### Octane

Larahost support Laravel Octane with swoole. First install package `laravel/octane` using composer:

```bash
composer require laravel/octane
# then
php artisan octane:install
```

Then add below environment variables to your `docker-compose.yml`:

* `LARAHOST_OCTANE_ENABLED` - Enable or disable Octane. Default value is `false`.
* `LARAHOST_OCTANE_WORKERS` - Number of workers to run. Default value is `4`.
* `LARAHOST_OCTANE_TASK_WORKERS` - Number of task workers to run. Default value is `6`.
* `LARAHOST_OCTANE_ENABLE_LOG` - Enable or disable logs. default value is `false`.

> ### Horizon

Larahost support Laravel Horizon. First install package `laravel/horizon` using composer:

```bash
composer require laravel/horizon
# then
php artisan horizon:install
```

Then add below variables to your `docker-compose.yml`:

* `LARAHOST_HORIZON_ENABLED` - Enable or disable Horizon. Default value is `false`.
* `LARAHOST_HORIZON_ENABLE_LOG` - Enable logs. default value is `false`.

> ### Queues

Larahost support Laravel queues. Add below environment variables to your `docker-compose.yml`:

* `QUEUES_ENABLED` - Enable Queues. Default value is `false`.
* `LARAHOST_QUEUE_NAMES` - Queues names. Default value is `default:1` (Format `QueueName:WorkersNumber`). You can add multiple queues like `default:1,bulk:10,mail:3`.
* `LARAHOST_QUEUE_ENABLE_LOG` - Enable or disable logs. default value is `false`.

> ### Nginx

Larahost uses Nginx as web server. PHP-FPM used as default upstream and it does not require any configuration. PHP-FPM will be auto disabled if you enable Octane.

Only available environment variables:

* `LARAHOST_NGINX_CLIENT_MAX_BODY_SIZE` - Set maximum allowed size for client request body. Default value is `1M`.

> ### PHP

PHP-FPM configurable environment variables in `docker-compose.yml`:

* `LARAHOST_PHP_ALLOW_URL_FOPEN` - Whether to allow the treatment of URLs (like http:// or ftp://) as files. Default value is `Off`.
* `LARAHOST_PHP_DISPLAY_ERRORS` - Whether to display errors in the browser. Default value is `Off`.
* `LARAHOST_PHP_FILE_UPLOADS` - Whether to allow HTTP file uploads. Default value is `On`.
* `LARAHOST_PHP_MAX_EXECUTION_TIME` - Maximum execution time of each script, in seconds. Default value is `30`.
* `LARAHOST_PHP_MAX_INPUT_TIME` - Maximum amount of time each script may spend parsing request data. Default value is `60`.
* `LARAHOST_PHP_MAX_INPUT_VARS` - Maximum number of input variables allowed per request. Default value is `1000`.
* `LARAHOST_PHP_MEMORY_LIMIT` - Maximum amount of memory a script may consume. Default value is `128M`.
* `LARAHOST_PHP_POST_MAX_SIZE` - Maximum size of POST data that PHP will accept. Default value is `1M`.
* `LARAHOST_PHP_UPLOAD_MAX_FILESIZE` - Maximum allowed size for uploaded files. Default value is `1M`.
* `LARAHOST_PHP_ZLIB_OUTPUT_COMPRESSION` - Whether to transparently compress pages. Default value is `On`.
* `LARAHOST_PHP_CLEAR_ENV` - Whether to clear environment before running child processes. Default value is `no`.
* `LARAHOST_PHP_CA_CERT` - Path to CA bundle file. Default value is ``.


## Full docker-compose.yml example
Below is full example of `docker-compose.yml` file:

```yaml
version: '3'

services:
  app:
    container_name: app
    # check https://hub.docker.com/r/humaid/larahost/tags for available tags
    image: ${LARAHOST_IMAGE:-humaid/larahost:8.2}
    restart: unless-stopped
    environment:
      TZ: ${LARAHOST_TZ:-Asia/Dubai} # Timezone
      LARAHOST_UID: ${LARAHOST_UID:-1000} # UID
      LARAHOST_GID: ${LARAHOST_GID:-1000} # GID
      # horizon
      LARAHOST_HORIZON_ENABLED: ${LARAHOST_HORIZON_ENABLED:-false}
      LARAHOST_HORIZON_ENABLE_LOG: ${LARAHOST_HORIZON_LOGFILE:-/dev/fd/1}
      # octane
      LARAHOST_OCTANE_ENABLED: ${LARAHOST_OCTANE_ENABLED:-false}
      LARAHOST_OCTANE_WORKERS: ${LARAHOST_OCTANE_WORKERS:-4}
      LARAHOST_OCTANE_TASK_WORKERS: ${LARAHOST_OCTANE_TASK_WORKERS:-6}
      LARAHOST_OCTANE_ENABLE_LOG: ${LARAHOST_OCTANE_ENABLE_LOG:-false}
      # Queues
      LARAHOST_QUEUE_ENABLED: ${LARAHOST_QUEUE_ENABLED:-false}
      LARAHOST_QUEUE_NAMES: ${LARAHOST_QUEUE_NAMES:-'default:1'}
      LARAHOST_QUEUE_ENABLE_LOG: ${LARAHOST_QUEUE_ENABLE_LOG:-false}
      #nginx
      LARAHOST_NGINX_CLIENT_MAX_BODY_SIZE: ${LARAHOST_NGINX_CLIENT_MAX_BODY_SIZE:-1M}
      #cron (if test mode  is enabled, cron will only log date in the root folder and will not run any command)
      LARAHOST_CRON_ENABLED: ${LARAHOST_CRON_ENABLED:-false}
      # php
      LARAHOST_PHP_ALLOW_URL_FOPEN: ${LARAHOST_PHP_ALLOW_URL_FOPEN:-On}
      LARAHOST_PHP_ALLOW_URL_INCLUDE: ${LARAHOST_PHP_ALLOW_URL_INCLUDE:-Off}
      LARAHOST_PHP_DISPLAY_ERRORS: ${LARAHOST_PHP_DISPLAY_ERRORS:-Off}
      LARAHOST_PHP_FILE_UPLOADS: ${LARAHOST_PHP_FILE_UPLOADS:-On}
      LARAHOST_PHP_MAX_EXECUTION_TIME: ${LARAHOST_PHP_MAX_EXECUTION_TIME:-30}
      LARAHOST_PHP_MAX_INPUT_TIME: ${LARAHOST_PHP_MAX_INPUT_TIME:-300}
      LARAHOST_PHP_MAX_INPUT_VARS: ${LARAHOST_PHP_MAX_INPUT_VARS:-1000}
      LARAHOST_PHP_MEMORY_LIMIT: ${LARAHOST_PHP_MEMORY_LIMIT:-1024M}
      LARAHOST_PHP_POST_MAX_SIZE: ${LARAHOST_PHP_POST_MAX_SIZE:-1M}
      LARAHOST_PHP_UPLOAD_MAX_FILESIZE: ${LARAHOST_PHP_UPLOAD_MAX_FILESIZE:-1M}
      LARAHOST_PHP_ZLIB_OUTPUT_COMPRESSION: ${LARAHOST_PHP_ZLIB_OUTPUT_COMPRESSION:-On}
      LARAHOST_PHP_CLEAR_ENV: ${LARAHOST_PHP_CLEAR_ENV:-no}
      LARAHOST_PHP_CA_CERT: ${LARAHOST_PHP_CA_CERT:-''}
    ports:
      - "${LARAHOST_PORT:-80:80}"
    volumes:
      - ./:/home/docker/www
```

.env variables:

```dotenv
LARAHOST_TZ=Asia/Dubai
#LARAHOST_UID=501
#LARAHOST_GID=80
LARAHOST_PORT="12000:80"
# horizon
LARAHOST_HORIZON_ENABLED=false
LARAHOST_HORIZON_ENABLE_LOG=false
# octane
LARAHOST_OCTANE_ENABLED=false
LARAHOST_OCTANE_WORKERS=4
LARAHOST_OCTANE_TASK_WORKERS=6
LARAHOST_OCTANE_ENABLE_LOG=false
# laravel queue
LARAHOST_QUEUE_ENABLED=false
LARAHOST_QUEUE_NAMES='default:1,bulk:10,mail:3'
LARAHOST_QUEUE_ENABLE_LOG=false
#nginx
LARAHOST_NGINX_CLIENT_MAX_BODY_SIZE=8M
#cron
LARAHOST_CRON_ENABLED=false
# php
LARAHOST_PHP_ALLOW_URL_FOPEN=Off
LARAHOST_PHP_ALLOW_URL_INCLUDE=On
LARAHOST_PHP_DISPLAY_ERRORS=On
LARAHOST_PHP_FILE_UPLOADS=On
LARAHOST_PHP_MAX_EXECUTION_TIME=60
LARAHOST_PHP_MAX_INPUT_TIME=600
LARAHOST_PHP_MAX_INPUT_VARS=1200
LARAHOST_PHP_MEMORY_LIMIT=512M
LARAHOST_PHP_POST_MAX_SIZE=8M
LARAHOST_PHP_UPLOAD_MAX_FILESIZE=8M
LARAHOST_PHP_ZLIB_OUTPUT_COMPRESSION=Off
LARAHOST_PHP_CLEAR_ENV=yes
LARAHOST_PHP_CA_CERT=
```

### Resources
* [Docker Hub](https://hub.docker.com/r/humaid/larahost)
* [GitHub](https://github.com/humaidem/larahost)
