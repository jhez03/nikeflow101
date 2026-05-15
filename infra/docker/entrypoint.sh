#!/bin/sh
set -e
# set -e: exit on first error. Prevents silent failures where the container
# appears to start but is actually in a broken state.

echo "Starting Laravel container..."

# --- Docker Secrets loader ---
# Docker Swarm mounts secrets as files at /run/secrets/<secret_name>.
# Falls back silently to the existing env var value when no secret file exists
# (e.g., local development with plain env vars).
load_secret() {
    local var_name="$1"
    local secret_name="$2"
    local secret_file="/run/secrets/${secret_name}"
    if [ -f "$secret_file" ]; then
        export "${var_name}=$(tr -d '\n' <"$secret_file")"
    fi
}

load_secret APP_KEY app_key
load_secret DB_PASSWORD db_password
load_secret DB_USERNAME db_username
load_secret REDIS_PASSWORD redis_password

if [ "$DB_CONNECTION" = "mysql" ]; then
    echo "Waiting for MySQL at $DB_HOST..."
    DB_WAIT_ATTEMPTS=0
    DB_WAIT_MAX=30
    until php -r "
    try {
      \$dsn = 'mysql:host=' . getenv('DB_HOST') . ';dbname=' . getenv('DB_DATABASE');
      new PDO(\$dsn, getenv('DB_USERNAME'), getenv('DB_PASSWORD'));
      exit(0);
    } catch (Exception \$e) {
      exit(1);
    }
  " 2>/dev/null; do
        DB_WAIT_ATTEMPTS=$((DB_WAIT_ATTEMPTS + 1))
        if [ "$DB_WAIT_ATTEMPTS" -ge "$DB_WAIT_MAX" ]; then
            echo "ERROR: MySQL at $DB_HOST did not become ready after ${DB_WAIT_MAX} attempts. Exiting."
            exit 1
        fi
        echo "  DB not ready, retrying in 2s... ($DB_WAIT_ATTEMPTS/$DB_WAIT_MAX)"
        sleep 2
    done
    echo "Database is ready."
fi

# --- Run migrations ---
# --force bypasses the interactive confirmation artisan shows in non-local APP_ENV.
# This is safe here because we deploy to a controlled staging environment.
# For blue/green production deploys, run migrate as a pre-deploy job instead.
php artisan migrate --force

# --- Laravel optimizations ---
# These pre-compile config, routes, and views into PHP opcache-friendly files.
# They MUST run at container start (not at image build time) because they read
# env vars like APP_KEY, DB_HOST, STRIPE_SECRET_KEY — which only exist at runtime.
# First startup is ~3s slower; every subsequent request is faster.
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "Laravel is ready. Starting PHP-FPM..."

# exec "$@" replaces this shell process with the CMD (default: php-fpm, set in Dockerfile).
# Using "$@" instead of hardcoding `php-fpm` allows worker/scheduler containers to override
# the command (e.g., `php artisan queue:work`) while still running through this entrypoint
# for secret loading, DB wait, and migrations.
exec "$@"
