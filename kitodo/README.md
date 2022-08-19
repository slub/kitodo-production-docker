# Kitodo.Production Docker

 * [Prerequisites](#prerequisites)
 * [Quickstart](#quickstart)
 * [Services](#services)
 * [Configuration](#configuration)
   * [Structure](#usage)
     * [Single compose project](#single-compose-project)
     * [Multi compose project](#multi-compose-project)

With the docker image provided, Kitodo.Production can be started in no time at all. A MySQL/MariaDB database and ElasticSearch must be present to start the application. There is also a docker-compose file for a quick start.

## Prerequisites

Install Docker Engine
https://docs.docker.com/get-docker/

Install Docker Compose
https://docs.docker.com/compose/install/

## Quickstart 

Go to the directory where you've put docker-compose.yml.

Copy the environment `.env.example` inside the directory and rename file to `.env`. 

Build and start all service containers
```
docker-compose up -d --build
```

Stops all service containers
```
docker-compose stop
```

Stops and remove all service containers
```
docker-compose down
```

## Services



## Configuration

### Structure

There are the following two options of usage.

#### Single compose project (default)

If only one project instance is needed or repository is used as submodule in other projects.

Build image before and start the container of image
```
docker-compose up -d --build
```

Stops the container
```
docker-compose stop
```

Stops and remove the container
```
docker-compose down
```

#### Multi compose project

Go to the directory where you've put docker-compose.yml. Create subdirectory where you want to store your compose projects.
In our examples we named it "projects". Create project directory (e.g. my-compose-project) in subdirectory where you want to store your compose project data.

###### Usage with project name parameter

Copy `.env.example`, rename file to `.env`, uncomment `COMPOSE_PROJECT_NAME` and comment out the single compose project variables and uncomment the multiple compose project variables

```
docker-compose -p my-compose-project ... # ... means command e.g. up -d --build
```

###### Usage with env file in project folder

Copy the `.env.example` to project directory, rename file to `.env` and change value of `COMPOSE_PROJECT_NAME` env to the name of project directory and comment out the single compose project variables and uncomment the multiple compose project variables

```
docker-compose --env-file ./projects/my-compose-project/.env ... # ... means command e.g. up -d --build
```

### Application Service Overwrites

#### Builder

First you have to decide which type to use for providing the build resources

##### Release

Release files of any [release of Kitodo.Production](https://github.com/kitodo/kitodo-production/releases) will be used to build Kitodo.Production image.

##### Git

Archive with specified commit / branch and source url will be downloaded. Futhermore builder triggers maven to build sources, creates database and migrate database using flyway migration steps. After build resource files will be renamed and moved to build resource folder.

##### Local

#### Debug

#### Dev









The resource builder use a git release tag or git repository archive as source to generate build resources. These are provided to the image builder via 

Argument

| Name | Default | Description
| --- | --- | --- |
| BUILDER_TYPE | RELEASE | available types RELEASE and GIT<br/>- RELEASE means build the build resources by a [Kitodo.Production Release](https://github.com/kitodo/kitodo-production/tags) and its assets<br/>- GIT means build the build resources by commit/branch and |

| Name | Default | Description
| --- | --- | --- |
| BUILDER_LOCAL_WAR | build-resources/kitodo.war | Relative WAR file path |
| BUILDER_LOCAL_SQL | build-resources/kitodo.sql | Relative SQL file path |
| BUILDER_LOCAL_CONFIG_MODULES_ZIP | build-resources/kitodo-config-modules.zip | Relative config modules ZIP file path |

### Resource Builder (default)

Release files of any [release of Kitodo.Production](https://github.com/kitodo/kitodo-production/releases) will be used to build Kitodo.Production image.


### Git Builder

Archive with specified commit / branch and source url will be downloaded. Next builder triggers maven to build sources, creates database and migrate database using flyway migration steps. After build resource files will be renamed and moved to build resource folder.

### Local Builder

#### Arguments

| Name | Default | Description
| --- | --- | --- |
| BUILDER_LOCAL_WAR | build-resources/kitodo.war | Relative WAR file path |
| BUILDER_LOCAL_SQL | build-resources/kitodo.sql | Relative SQL file path |
| BUILDER_LOCAL_CONFIG_MODULES_ZIP | build-resources/kitodo-config-modules.zip | Relative config modules ZIP file path |

## Image Builder

The image contains the WAR, the database file and the config modules of the corresponding release for the Docker image tag.

```
docker pull markusweigelt/kitodo-production:TAG
```

After the container has been started Kitodo.Production can be reached at http://localhost:8080/kitodo with initial credentials username "testadmin" and password "test".

#### Environment variables

| Name | Default | Description
| --- | --- | --- |
| DB_HOST | localhost | Host of MySQL or MariaDB database |
| DB_PORT | 3306 | Port of MySQL or MariaDB database |
| DB_NAME | kitodo | Name of database used by Kitodo.Productions |
| DB_USER | kitodo | Username to access database |
| DB_PASSWORD | kitodo | Password used by username to access database |
| ES_HOST | localhost | Host of Elasticsearch |
| MQ_HOST | localhost | Host of Active MQ |
| MQ_PORT | 61616 | Port of Active MQ |

#### Targets

| Name | Path | Description
| --- | --- | --- |
| Config Modules | /usr/local/kitodo | If the directory is mounted or bind per volume and is empty, then it will be prefilled with the provided config modules of the release. |

#### Database 

If the database is still empty, it will be initialized with the database script from the release.
