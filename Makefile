ENV_FILE ?= ./kitodo/.env

build:
	docker-compose --env-file $(ENV_FILE) -f ./kitodo/docker-compose.yml -f ./kitodo/docker-compose-builder.yml up --build kitodo-builder

up: ./kitodo/build-resources
	docker-compose --env-file $(ENV_FILE) -f ./kitodo/docker-compose.yml up -d --build

down:
	docker-compose --env-file $(ENV_FILE) -f ./kitodo/docker-compose.yml down