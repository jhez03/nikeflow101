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

ARG ACTIVE_THEME=default
ENV ACTIVE_THEME=${ACTIVE_THEME}

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

WORKDIR /var/www

COPY --from=composer-builder /app/vendor ./vendor

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
# Stage 5: nginx-stage — static asset server for Swarm deployment
# In Swarm, assets cannot be extracted via `docker create`+`docker cp`.
# This image ships public/build and nginx config so it deploys as a
# standalone Swarm service alongside the PHP image.
# ============================================================
FROM nginx:1.27-alpine AS nginx-stage

COPY --from=node-builder /app/public/build /var/www/public/build
COPY --from=composer-builder /app/public /var/www/public
COPY infra/docker/nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
