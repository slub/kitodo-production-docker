SHELL = /bin/bash

PROJECT_NAME ?=
ifndef PROJECT_NAME
$(error PROJECT_NAME is not set)
endif

BUILDER ?= 
ifndef BUILDER
$(error BUILDER is not set)
endif

ENVFILE = ./projects/${PROJECT_NAME}/.env
ifeq (git,$(BUILDER))
COMPOSE_FILE = docker-compose.yml:./overwrites/docker-compose-app-builder-git.yml:./overwrites/docker-compose-log.yml
else ifeq (local,$(BUILDER))
COMPOSE_FILE = docker-compose.yml:./overwrites/docker-compose-app-builder-local.yml:./overwrites/docker-compose-log.yml
else
COMPOSE_FILE = docker-compose.yml:./overwrites/docker-compose-app-builder-release.yml:./overwrites/docker-compose-log.yml
endif

DEBUG ?= false
ifeq (true,$(DEBUG))
COMPOSE_FILE += :./overwrites/docker-compose-app-debug.yml
endif

DEV ?= false
ifeq (true,$(DEV))
COMPOSE_FILE += :./overwrites/docker-compose-app-dev.yml
endif

COMPOSE_PATH_SEPARATOR = :

.EXPORT_ALL_VARIABLES:

info:
	$(info    PROJECT_NAME is $(PROJECT_NAME))
	$(info    BUILDER is $(BUILDER))
	$(info    DEBUG is $(DEBUG))
	$(info    DEV is $(DEV))

clean:
	$(RM) -r ./projects/${PROJECT_NAME}

prepare: ./projects/${PROJECT_NAME}/.env

./projects/${PROJECT_NAME}/.env:
	mkdir -p ./projects/${PROJECT_NAME}/
	cp .env.example $@
# Multiple compose projects variables
	sed -i 's/COMPOSE_PROJECT_NAME=kitodo-production-docker/COMPOSE_PROJECT_NAME=${PROJECT_NAME}/g' $@
	sed -i 's/kitodo-production:latest/kitodo-production\/${PROJECT_NAME}:latest/g' $@
	sed -i 's/#APP_PROJECT_PATH/APP_PROJECT_PATH/g' $@
	sed -i 's/#APP_DATA/APP_DATA/g' $@

build:
	docker-compose --env-file ${ENVFILE} build --no-cache

start:
	docker-compose --env-file ${ENVFILE} up -d

down:
	docker-compose --env-file ${ENVFILE} down

stop:
	docker-compose --env-file ${ENVFILE} stop

config:
	docker-compose --env-file ${ENVFILE} config

status:
	docker-compose --env-file ${ENVFILE} ps


.PHONY: info clean prepare build start down stop config status

# do not search for implicit rules here:
%.zip: ;
Makefile: ;
