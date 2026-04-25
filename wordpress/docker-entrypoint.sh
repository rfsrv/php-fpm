#!/bin/sh
# wordpress/docker-entrypoint.sh
#
# WordPress-specific startup logic layered on top of the base entrypoint.
# Runs the base image's entrypoint first (PHP ini / FPM pool generation),
# then performs WordPress-specific setup before handing off to php-fpm.

set -e

# ── W3TC drop-in files ────────────────────────────────────────────────────────
# W3TC ships its drop-ins inside the plugin directory but WordPress needs them
# at the content root (web/app/*.php).  Copy any that are missing so W3TC can
# initialise on first boot without requiring a manual WP-admin save step.
W3TC_PLUGIN_DIR="/var/www/html/web/app/plugins/w3-total-cache/wp-content"
W3TC_APP_DIR="/var/www/html/web/app"
for dropin in advanced-cache.php object-cache.php db.php; do
    src="${W3TC_PLUGIN_DIR}/${dropin}"
    dst="${W3TC_APP_DIR}/${dropin}"
    if [ -f "$src" ] && [ ! -f "$dst" ]; then
        cp "$src" "$dst"
        chown 82:82 "$dst"
        chmod 644 "$dst"
        echo "w3tc: installed drop-in ${dropin}"
    fi
done

# Hand off to the base entrypoint (generates php.ini + fpm pool, then execs php-fpm)
exec /usr/local/bin/base-docker-entrypoint.sh "$@"
