FROM php:8.4-fpm-alpine

WORKDIR /var/www

RUN apk add --no-cache \
    git curl unzip \
    libpng-dev oniguruma-dev libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-autoloader --prefer-dist

COPY . .

RUN composer dump-autoload --optimize

RUN chmod -R 775 storage bootstrap/cache   # 775 is safer than 777

RUN addgroup -g 1000 www && adduser -u 1000 -D -G www www \
    && chown -R www:www storage bootstrap/cache

COPY infra/docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER www

EXPOSE 9000

ENTRYPOINT ["entrypoint.sh"]
