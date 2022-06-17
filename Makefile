.PHONY: all
default: all;

# Together with the Dockerfile detect if in the container shell
ifndef PHP_IN_CONTAINER
    CMD_EXEC := docker-compose -f infrastructure/docker-compose.dev.yml --project-directory $(CURDIR) exec php
endif

build:
	docker-compose -f infrastructure/docker-compose.dev.yml --project-directory $(CURDIR) build --no-cache

start:
	docker-compose -f infrastructure/docker-compose.dev.yml --project-directory $(CURDIR) up -d

stop:
	docker-compose -f infrastructure/docker-compose.dev.yml --project-directory $(CURDIR) down --remove-orphans

shell:
	docker-compose -f infrastructure/docker-compose.dev.yml --project-directory $(CURDIR) exec php bash

style:
	${CMD_EXEC} vendor/bin/phpcs --standard=PSR12 src/

fmt:
	${CMD_EXEC} vendor/bin/phpcbf --standard=PSR12 src/

phpstan:
	${CMD_EXEC} vendor/bin/phpstan analyze

install:
	docker run -it --rm -v $(echo "$HOME/.composer"):/tmp -v $(CURDIR):/app composer:2 install --ignore-platform-req=ext-sockets

all: install start shell
