#!/bin/sh
# wp-cron-run — run due WP-Cron events via WP-CLI.
#
# Designed to be called by supercronic (cron sidecar) or directly from a
# k8s CronJob.  Exits 0 on success, non-zero on failure so supercronic /
# the job controller can detect problems.
#
# Environment:
#   WP_PATH   Path to the WordPress installation directory.
#             Defaults to the Bedrock convention: web/wp relative to WORKDIR.
#   WP_URL    Optional --url flag (needed for multisite or non-standard setups).

set -eu

WP_PATH="${WP_PATH:-/var/www/html/web/wp}"

WP_ARGS="--path=${WP_PATH} --allow-root"
if [ -n "${WP_URL:-}" ]; then
  WP_ARGS="${WP_ARGS} --url=${WP_URL}"
fi

exec wp ${WP_ARGS} cron event run --due-now
