#!/bin/sh
# Caddy entrypoint — reads the bcrypt hash from a Docker Swarm secret and
# exports it as CADDY_BASIC_AUTH_HASH so the Caddyfile can reference it
# with {env.CADDY_BASIC_AUTH_HASH} without baking the value into the image.
set -e

if [ -f /run/secrets/caddy_basic_auth_hash ]; then
    export CADDY_BASIC_AUTH_HASH=$(cat /run/secrets/caddy_basic_auth_hash)
fi

exec "$@"
