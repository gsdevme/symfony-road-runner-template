FROM php:8.1-cli AS base

ENV PHP_IN_CONTAINER=1

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

RUN docker-php-ext-install -j$(nproc) zip intl sockets && chmod +x /usr/local/bin/entrypoint.sh

CMD ["rr", "serve"]
WORKDIR "/app"
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

FROM base as dev

CMD ["rr", "serve", "-c", ".rr.dev.yaml"]

FROM base as test

RUN make style && make phpstan

FROM test as prod

ENV APP_ENV=prod
ENV APP_DEBUG=0


