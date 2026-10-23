#!/bin/sh
set -e

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

# started with `user:` in compose: can't switch users, run as-is
if [ "$(id -u)" != "0" ]; then
    exec "$@"
fi

chown -R "$PUID:$PGID" /config

exec su-exec "$PUID:$PGID" "$@"
