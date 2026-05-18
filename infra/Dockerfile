# ============================================================
# Stage 1: Composer builder — installs PHP production dependencies
# ============================================================
FROM composer:2 AS composer-builder

WORKDIR /app
COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist \
    --ignore-platform-req=ext-bcmath

COPY . .

RUN composer dump-autoload --optimize --no-dev

# ============================================================
# Stage 2: Node builder — compiles Vue/Vite frontend assets
# ============================================================
FROM node:22-alpine AS node-builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci --ignore-scripts

COPY . .

COPY --from=composer-builder /app/vendor/tightenco ./vendor/tightenco

RUN NODE_ENV=production npm run build

# ============================================================
# Stage 3: Runtime image — only what PHP-FPM needs at runtime
# ============================================================
FROM php:8.4-fpm-alpine AS runtime
RUN apk add --no-cache \
    curl \
    libpng-dev \
    oniguruma-dev \
    libxml2-dev \
    icu-dev \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        intl \
    && docker-php-ext-enable opcache

RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

WORKDIR /var/www

COPY --from=composer-builder /app/vendor ./vendor
COPY --from=node-builder /app/public/build ./public/build

COPY . .


COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
RUN composer dump-autoload --optimize --no-dev \
    && rm /usr/local/bin/composer

RUN chmod -R 775 storage bootstrap/cache

RUN addgroup -g 1000 www \
    && adduser -u 1000 -D -G www www \
    && chown -R www:www /var/www

COPY infra/docker/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY infra/docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER www

EXPOSE 9000

CMD ["php-fpm"]
ENTRYPOINT ["entrypoint.sh"]

# ============================================================
# Stage 4: Development image — extends runtime, adds Composer
# ============================================================
FROM runtime AS development

USER root
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
USER www

# ============================================================
# Stage 5: caddy-stage — Caddy serving static assets + FastCGI proxy.
# In Swarm, assets cannot be shared via volumes across nodes.
# This image bakes in public/build so Caddy can serve them directly,
# replacing the old nginx-stage image. Caddy handles TLS, static files,
# and FastCGI proxying to php:9000 in a single container.
# ============================================================
FROM caddy:2-alpine AS caddy-stage

COPY --from=node-builder /app/public /var/www/public
COPY infra/Caddyfile /etc/caddy/Caddyfile

# Entrypoint reads the caddy_basic_auth_hash Docker secret and exports it as
# CADDY_BASIC_AUTH_HASH before exec-ing Caddy, so the Caddyfile can reference
# {env.CADDY_BASIC_AUTH_HASH} without the hash ever being baked into the image.
COPY infra/docker/caddy-entrypoint.sh /usr/local/bin/caddy-entrypoint.sh
RUN chmod +x /usr/local/bin/caddy-entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/usr/local/bin/caddy-entrypoint.sh"]
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
