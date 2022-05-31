ENV_FILE ?= ./kitodo/.env

build: ./kitodo/build-resources

./kitodo/build-resources:
	docker-compose --env-file $(ENV_FILE) -f ./kitodo/docker-compose.yml -f ./kitodo/docker-compose-builder.yml up --build kitodo-builder
	docker-compose --env-file $(ENV_FILE) -f ./kitodo/docker-compose.yml -f ./kitodo/docker-compose-builder.yml down

up: ./kitodo/build-resources
	docker-compose --env-file $(ENV_FILE) -f ./kitodo/docker-compose.yml up -d --build

down:
	docker-compose --env-file $(ENV_FILE) -f ./kitodo/docker-compose.yml down

stop:
	docker-compose --env-file $(ENV_FILE) -f ./kitodo/docker-compose.yml stop

clean:
	rm -rf ./kitodo/build-resources