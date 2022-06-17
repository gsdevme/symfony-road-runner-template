FROM php:8.1-cli AS base

ENV PHP_IN_CONTAINER=1

COPY infrastructure/opcache.ini $PHP_INI_DIR/conf.d/zz-opcache.ini
COPY infrastructure/entrypoint.sh /usr/local/bin/entrypoint.sh

COPY --from=ghcr.io/roadrunner-server/roadrunner:2.10.4 /usr/bin/rr /usr/local/bin/rr
COPY --from=composer:2.3 /usr/bin/composer /usr/local/bin/composer

RUN buildDeps=" \
        wget \
        git \
        less \
        zip \
        unzip \
        libzip-dev \
        libicu-dev \
    "; \
    set -x \
    && apt-get update \
    && apt-get install -y $buildDeps --no-install-recommends

RUN docker-php-ext-install -j$(nproc) zip intl sockets opcache && chmod +x /usr/local/bin/entrypoint.sh

CMD ["rr", "serve"]
WORKDIR "/app"
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

FROM base as dev

# Override for development
COPY infrastructure/opcache-dev.ini $PHP_INI_DIR/conf.d/zzz-opcache.ini

CMD ["rr", "serve", "-c", ".rr.dev.yaml"]

FROM base as build

COPY . .

RUN mkdir -p /app/var && chown -R www-data:www-data /app/

RUN composer install --no-interaction --no-scripts --no-suggest --no-progress

FROM build as ci

RUN make style && \
    make phpstan && \
    make phpunit && \
    bin/console lint:container && \
    bin/console lint:yaml config

FROM base as prod

ENV APP_ENV=prod
ENV APP_DEBUG=0

COPY --from=build /app/ /app/

RUN composer dump-autoload --no-dev --classmap-authoritative && \
    chown -R www-data:www-data /app/

USER www-data
