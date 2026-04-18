# WordPress / Bedrock variant of the rfsrv php-fpm base image.
#
# Additions over the base:
#   - WP-CLI        — for maintenance, migrations, and running wp-cron
#   - supercronic   — container-native cron daemon used to drive WP-Cron
#
# Deployment modes (select via CMD / k8s command override):
#   php-fpm (default):   php-fpm
#   WP-Cron sidecar:     supercronic /etc/supercronic/crontab
#   One-off WP-CLI:      wp <args>

ARG BASE_IMAGE=ghcr.io/rfsrv/php-fpm
ARG PHP_VERSION=8.3

FROM ${BASE_IMAGE}:${PHP_VERSION}

ARG WPCLI_VERSION=2.11.0
ARG SUPERCRONIC_VERSION=0.2.33

# Install WP-CLI
RUN set -eux; \
    curl -fsSL \
        "https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar" \
        -o /usr/local/bin/wp; \
    chmod +x /usr/local/bin/wp; \
    wp --allow-root --version

# Install supercronic (container-native cron — no syslog, clean signal handling)
RUN set -eux; \
    ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/'); \
    curl -fsSL \
        "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-${ARCH}" \
        -o /usr/local/bin/supercronic; \
    chmod +x /usr/local/bin/supercronic

# WordPress-tuned PHP overrides (uploads, execution time, memory)
COPY php/conf.d/wordpress.ini /usr/local/etc/php/conf.d/zz-wordpress.ini

# Crontab consumed by supercronic when used as the cron sidecar/job
RUN mkdir -p /etc/supercronic
COPY cron/crontab /etc/supercronic/crontab

# Helper script that normalises WP path and forwards args to WP-CLI
COPY scripts/wp-cron-run.sh /usr/local/bin/wp-cron-run
RUN chmod +x /usr/local/bin/wp-cron-run

WORKDIR /var/www/html
EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 | grep -q "pong" || exit 1

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php-fpm"]
