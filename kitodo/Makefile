SHELL = /bin/bash

PROJECT_NAME ?=
ifndef PROJECT_NAME
$(error PROJECT_NAME is not set)
endif

BUILDER ?= 
ifndef BUILDER
$(error BUILDER is not set)
endif
BUILDER_GIT_COMMIT ?= master
BUILDER_GIT_SOURCE_URL ?= https://github.com/kitodo/kitodo-production/

ENVFILE = ./projects/${PROJECT_NAME}/.env
ifeq (git,$(BUILDER))
COMPOSE_FILE = docker-compose.yml:./overwrites/docker-compose-app-builder-git.yml:./overwrites/docker-compose-logviewer.yml
else ifeq (local,$(BUILDER))
COMPOSE_FILE = docker-compose.yml:./overwrites/docker-compose-app-builder-local.yml:./overwrites/docker-compose-logviewer.yml
else
COMPOSE_FILE = docker-compose.yml:./overwrites/docker-compose-app-builder-release.yml:./overwrites/docker-compose-logviewer.yml
endif

DEBUG ?= false
ifeq (true,$(DEBUG))
COMPOSE_FILE := $(COMPOSE_FILE):./overwrites/docker-compose-app-debug.yml
endif

DEV ?= false
ifeq (true,$(DEV))
COMPOSE_FILE := $(COMPOSE_FILE):./overwrites/docker-compose-app-dev.yml
endif

COMPOSE_PATH_SEPARATOR = :

.EXPORT_ALL_VARIABLES:

info:
	$(info    PROJECT_NAME is $(PROJECT_NAME))
	$(info    BUILDER is $(BUILDER))
	@if [ "$(BUILDER)" = "git" ]; then\
		echo "BUILDER_GIT_COMMIT is $(BUILDER_GIT_COMMIT)";\
		echo "BUILDER_GIT_SOURCE_URL is $(BUILDER_GIT_SOURCE_URL)";\
	fi
	$(info    DEBUG is $(DEBUG))
	$(info    DEV is $(DEV))
	$(info    COMPOSE_FILE is $(COMPOSE_FILE))

clean:
	$(RM) -r ./projects/${PROJECT_NAME}

prepare: ./projects/${PROJECT_NAME}/.env

./projects/${PROJECT_NAME}/.env:
	mkdir -p ./projects/${PROJECT_NAME}/
	cp .env.example $@
# Multiple compose projects variables
	sed -i 's,COMPOSE_PROJECT_NAME=kitodo-production-docker,COMPOSE_PROJECT_NAME=${PROJECT_NAME},g' $@
	sed -i 's,markusweigelt/kitodo-production,kitodo-production/${PROJECT_NAME},g' $@
	sed -i 's,#APP_PROJECT_PATH,APP_PROJECT_PATH,g' $@
	sed -i 's,#APP_DATA,APP_DATA,g' $@
# Git builder variables
	sed -i 's,APP_BUILDER_GIT_COMMIT=master,APP_BUILDER_GIT_COMMIT=$(BUILDER_GIT_COMMIT),g' $@
	sed -i 's,APP_BUILDER_GIT_SOURCE_URL=https://github.com/kitodo/kitodo-production/,APP_BUILDER_GIT_SOURCE_URL=$(BUILDER_GIT_SOURCE_URL),g' $@

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


define HELP
cat <<"EOF"
Targets:
	- info:	show current set environment variables
	- prepare: create project directory, add .env file and overwrite values with project specific ones
	- build: `docker-compose build` all images (using parameter --no-cache)
	- start: `docker-compose up` all containers (in detached mode)
	- down:	`docker-compose down` all containers (i.e. stop and remove)
	- stop:	`docker-compose stop` all containers (i.e. only stop)
	- config: dump all the composed files
	- status: list running containers

Variables:
	- PROJECT_NAME name of project 
	- BUILDER type of builder (e.g. release, git, local)
	- BUILDER_GIT_COMMIT branch or commit number (is used when BUILDER=git)
	- BUILDER_GIT_SOURCE_URL repository url of BUILDER_GIT_COMMIT (is used when BUILDER=git)
EOF
endef
export HELP
help: ; @eval "$$HELP"


.PHONY: info clean prepare build start down stop config status help

# do not search for implicit rules here:
%.zip: ;
Makefile: ;
