# Kitodo.Production Docker Image

The docker image can be built with the release assets of Kitodo.Production GitHub tags https://github.com/kitodo/kitodo-production/tags.

### Arguments

| Name | Example | Description
| --- | --- | --- |
| KITODO_VERSION | 3.4.3 | Host of MySQL or MariaDB database |
| KITODO_WAR_NAME | kitodo-3.4.3 | Port of MySQL or MariaDB database |
| KITODO_SQL_NAME | kitodo_3-4-3 | Name of database used by Kitodo.Productions |
| KITODO_CONFIG_MODULES_NAME | kitodo_3-4-3_config_modules | Username to access database |

### Example

```
docker build -t markusweigelt/kitodo-production:3.4.1 --build-arg KITODO_VERSION=3.4.1 --build-arg KITODO_WAR_NAME=kitodo-3.4.1 --build-arg KITODO_SQL_NAME=kitodo_3-4-1 --build-arg KITODO_CONFIG_MODULES_NAME=kitodo_3-4-1_config_modules .
```

```
docker-compose --env-file C:/Users/weigelt/Work/kitodo/kitodo-production-projects/review-import-configuration/.env -f C:/Users/weigelt/Work/kitodo/kitodo-production-docker/docker-image/docker-compose.yml -f C:/Users/weigelt/Work/kitodo/kitodo-production-docker/docker-image/docker-compose-builder.yml up --build kitodo-builder
```

docker-compose --env-file ./projects/%%COMPOSE_PROJECT_NAME/.env -f ./docker-compose.yml -f ./docker-compose-builder.yml up --build kitodo-builder

docker-compose --env-file ./projects/%%COMPOSE_PROJECT_NAME/.env -f ./docker-compose.yml up --build kitodo-app