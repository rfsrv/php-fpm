#!/bin/sh
# docker-entrypoint.sh
#
# Renders PHP ini and FPM pool configuration from environment variables,
# then hands off to the standard php docker-php-entrypoint.
#
# PHP settings:     PHP_*          (e.g. PHP_MEMORY_LIMIT=256M)
# OPcache settings: PHP_OPCACHE_*  (e.g. PHP_OPCACHE_VALIDATE_TIMESTAMPS=0)
# FPM pool settings: PHP_PM_*      (e.g. PHP_PM_MAX_CHILDREN=30)
#
# All variables have sensible production defaults baked in below.
# Set any variable in your k8s Deployment / docker-compose env block to override.

set -e

# ── PHP ini defaults ──────────────────────────────────────────────────────────
: "${PHP_DATE_TIMEZONE:=UTC}"
: "${PHP_MEMORY_LIMIT:=128M}"
: "${PHP_MAX_EXECUTION_TIME:=30}"
: "${PHP_MAX_INPUT_TIME:=60}"
: "${PHP_MAX_INPUT_VARS:=1000}"
: "${PHP_POST_MAX_SIZE:=8M}"
: "${PHP_UPLOAD_MAX_FILESIZE:=8M}"
: "${PHP_DEFAULT_CHARSET:=UTF-8}"
: "${PHP_EXPOSE_PHP:=Off}"
: "${PHP_ERROR_REPORTING:=E_ALL & ~E_DEPRECATED & ~E_STRICT}"
: "${PHP_DISPLAY_ERRORS:=Off}"
: "${PHP_DISPLAY_STARTUP_ERRORS:=Off}"
: "${PHP_LOG_ERRORS:=On}"

# ── Session defaults ──────────────────────────────────────────────────────────
: "${PHP_SESSION_COOKIE_HTTPONLY:=1}"
: "${PHP_SESSION_COOKIE_SAMESITE:=Lax}"
: "${PHP_SESSION_COOKIE_SECURE:=0}"

# ── OPcache defaults ──────────────────────────────────────────────────────────
: "${PHP_OPCACHE_ENABLE:=1}"
: "${PHP_OPCACHE_ENABLE_CLI:=0}"
: "${PHP_OPCACHE_MEMORY_CONSUMPTION:=128}"
: "${PHP_OPCACHE_INTERNED_STRINGS_BUFFER:=16}"
: "${PHP_OPCACHE_MAX_ACCELERATED_FILES:=10000}"
: "${PHP_OPCACHE_REVALIDATE_FREQ:=60}"
: "${PHP_OPCACHE_VALIDATE_TIMESTAMPS:=1}"
: "${PHP_OPCACHE_FAST_SHUTDOWN:=1}"

# ── FPM pool defaults ─────────────────────────────────────────────────────────
# Sized for a 256Mi container limit (~50MB per WordPress child process).
# Override per-app via PHP_PM_* env vars (e.g. in kluctl resources.fpm.env).
: "${PHP_FPM_USER:=www-data}"
: "${PHP_FPM_GROUP:=www-data}"
: "${PHP_FPM_LISTEN:=0.0.0.0:9000}"
: "${PHP_PM:=dynamic}"
: "${PHP_PM_MAX_CHILDREN:=5}"
: "${PHP_PM_START_SERVERS:=2}"
: "${PHP_PM_MIN_SPARE_SERVERS:=1}"
: "${PHP_PM_MAX_SPARE_SERVERS:=3}"
: "${PHP_PM_MAX_REQUESTS:=500}"
: "${PHP_PM_PROCESS_IDLE_TIMEOUT:=10s}"

# ── Write PHP ini ─────────────────────────────────────────────────────────────
# Named zzz-env.ini so it loads last and overrides any other conf.d files.
cat > /usr/local/etc/php/conf.d/zzz-env.ini << EOF
; Auto-generated at container startup from environment variables.
; To override, set the corresponding PHP_* env vars.

[PHP]
date.timezone              = ${PHP_DATE_TIMEZONE}
memory_limit               = ${PHP_MEMORY_LIMIT}
max_execution_time         = ${PHP_MAX_EXECUTION_TIME}
max_input_time             = ${PHP_MAX_INPUT_TIME}
max_input_vars             = ${PHP_MAX_INPUT_VARS}
post_max_size              = ${PHP_POST_MAX_SIZE}
upload_max_filesize        = ${PHP_UPLOAD_MAX_FILESIZE}
default_charset            = ${PHP_DEFAULT_CHARSET}
expose_php                 = ${PHP_EXPOSE_PHP}
error_reporting            = ${PHP_ERROR_REPORTING}
display_errors             = ${PHP_DISPLAY_ERRORS}
display_startup_errors     = ${PHP_DISPLAY_STARTUP_ERRORS}
log_errors                 = ${PHP_LOG_ERRORS}

[Session]
session.cookie_httponly    = ${PHP_SESSION_COOKIE_HTTPONLY}
session.cookie_samesite    = ${PHP_SESSION_COOKIE_SAMESITE}
session.cookie_secure      = ${PHP_SESSION_COOKIE_SECURE}

[opcache]
opcache.enable                  = ${PHP_OPCACHE_ENABLE}
opcache.enable_cli              = ${PHP_OPCACHE_ENABLE_CLI}
opcache.memory_consumption      = ${PHP_OPCACHE_MEMORY_CONSUMPTION}
opcache.interned_strings_buffer = ${PHP_OPCACHE_INTERNED_STRINGS_BUFFER}
opcache.max_accelerated_files   = ${PHP_OPCACHE_MAX_ACCELERATED_FILES}
opcache.revalidate_freq         = ${PHP_OPCACHE_REVALIDATE_FREQ}
opcache.validate_timestamps     = ${PHP_OPCACHE_VALIDATE_TIMESTAMPS}
opcache.fast_shutdown           = ${PHP_OPCACHE_FAST_SHUTDOWN}
EOF

# ── Write FPM pool config ─────────────────────────────────────────────────────
# PHP-FPM errors on duplicate pool names, so the whole www.conf is regenerated.
cat > /usr/local/etc/php-fpm.d/www.conf << EOF
; Auto-generated at container startup from environment variables.
; To override, set the corresponding PHP_FPM_* / PHP_PM_* env vars.
[www]
user  = ${PHP_FPM_USER}
group = ${PHP_FPM_GROUP}

; Listen on TCP so nginx (in a separate container/pod) can connect
listen     = ${PHP_FPM_LISTEN}
ping.path  = /ping
pm.status_path = /status

; Process manager
pm                       = ${PHP_PM}
pm.max_children          = ${PHP_PM_MAX_CHILDREN}
pm.start_servers         = ${PHP_PM_START_SERVERS}
pm.min_spare_servers     = ${PHP_PM_MIN_SPARE_SERVERS}
pm.max_spare_servers     = ${PHP_PM_MAX_SPARE_SERVERS}
pm.max_requests          = ${PHP_PM_MAX_REQUESTS}
pm.process_idle_timeout  = ${PHP_PM_PROCESS_IDLE_TIMEOUT}

; Slow-log
request_slowlog_timeout = 10s
slowlog = /proc/self/fd/2

; Environment
clear_env                = no
catch_workers_output     = yes
decorate_workers_output  = no

; Logging
php_admin_value[error_log]  = /proc/self/fd/2
php_admin_flag[log_errors]  = on
EOF

exec docker-php-entrypoint "$@"
