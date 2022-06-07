# Kitodo.Production Docker

 * [Prerequisites](#prerequisites)
 * [Builder](#builder)
 * [Image](#image)

With the docker image provided, Kitodo.Production can be started in no time at all. A MySQL/MariaDB database and ElasticSearch must be present to start the application. There is also a docker-compose file for a quick start.

## Prerequisites

Install Docker Engine
https://docs.docker.com/get-docker/

Install Docker Compose
https://docs.docker.com/compose/install/

Go to the directory where you've put docker-compose.yml.

## Resource Builder

The resource builder use a git release tag or git repository archive as source to generate build resources. These are provided to the image builder via the build argument [BUILD_RESOURCES](#build-arguments). 

### Types

First you have to decide which type to use for providing the build resources

#### Release (default)

Release files will be downloaded, renamed and moved to build resource folder.

#### Git

Archive with specified commit / branch and source url will be downloaded. Next builder triggers maven to build sources, creates database and migrate database using flyway migration steps. After build resource files will be renamed and moved to build resource folder.

### Environment variables

| Name | Default | Description
| --- | --- | --- |
| APP_BUILD_CONTEXT | . | Directory of Dockerfile-Builder |
| APP_BUILD_RESOURCES | build-resources | Directory of build resource results for application |
| BUILDER_TYPE | RELEASE | available types RELEASE and GIT<br/>- RELEASE means build the build resources by a [Kitodo.Production Release](https://github.com/kitodo/kitodo-production/tags) and its assets<br/>- GIT means build the build resources by commit/branch and |
| BUILDER_RELEASE_VERSION | 3.4.3 | Release version name |
| BUILDER_RELEASE_WAR_NAME | kitodo-3.4.3 | Release asset war file name |
| BUILDER_RELEASE_SQL_NAME | kitodo_3-4-3 | Release assets sql file name |
| BUILDER_RELEASE_CONFIG_MODULES_NAME | kitodo_3-4-3_config_modules | Release asset config modules zip file name |
| BUILDER_GIT_COMMIT | master | Branch or commit of BUILDER_GIT_SOURCE_URL |
| BUILDER_GIT_SOURCE_URL | https://github.com/kitodo/kitodo-production/ | Repository of BUILDER_GIT_COMMIT |
| DB_PORT | 3306 | Port of database |
| DB_ROOT_PASSWORD | 1234 | Root password |
| DB_NAME | kitodo | Database name of Kitodo.Production |
| DB_USER | kitodo | User of DB_NAME |
| DB_USER_PASSWORD | kitodo | Password of DB_USER |

### Usage with docker-compose

Start building resources 
```
docker-compose --env-file ./kitodo/.env -f ./kitodo/docker-compose.yml -f ./kitodo/docker-compose-builder.yml up --build kitodo-builder
```

Remove resource builder 
```
docker-compose --env-file ./kitodo/.env -f ./kitodo/docker-compose.yml -f ./kitodo/docker-compose-builder.yml down
```

## Image Builder

The image contains the WAR, the database file and the config modules of the corresponding release for the Docker image tag.

```
docker pull markusweigelt/kitodo-production:TAG
```

After the container has been started Kitodo.Production can be reached at http://localhost:8080/kitodo with initial credentials username "testadmin" and password "test".

### Build arguments

| Name | Default | Description
| --- | --- | --- |
| BUILD_RESOURCES |  | Directory of build resources |
| BUILD_RESOURCE_WAR | kitodo.war | Name of application war in build resource directory |
| BUILD_RESOURCE_CONFIG_MODULES | kitodo-config-modules.zip | Name of config modules zip in build resource directory |
| BUILD_RESOURCE_SQL | kitodo.sql | Name of sql dump in build resource directory |

### Environment variables

| Name | Default | Description
| --- | --- | --- |
| KITODO_DB_HOST | localhost | Host of MySQL or MariaDB database |
| KITODO_DB_PORT | 3306 | Port of MySQL or MariaDB database |
| KITODO_DB_NAME | kitodo | Name of database used by Kitodo.Productions |
| KITODO_DB_USER | kitodo | Username to access database |
| KITODO_DB_PASSWORD | kitodo | Password used by username to access database |
| KITODO_ES_HOST | localhost | Host of Elasticsearch |
| KITODO_MQ_HOST | localhost | Host of Active MQ |
| KITODO_MQ_PORT | 61616 | Port of Active MQ |

### Targets

| Name | Path | Description
| --- | --- | --- |
| Config Modules | /usr/local/kitodo | If the directory is mounted or bind per volume and is empty, then it will be prefilled with the provided config modules of the release. |

### Database 

If the database is still empty, it will be initialized with the database script from the release.

## Using Docker Compose

### Starting 
```
docker-compose up -d
```

### Stopping 
```
docker-compose stop
```

### View Logs 
```
docker-compose logs -f
```
