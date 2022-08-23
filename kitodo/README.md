# Kitodo.Production Docker

 * [Prerequisites](#prerequisites)
 * [Quickstart](#quickstart)
 * [Services](#services)
   * [Environment file](#environment-file) 
   * [Application Service Overwrites](#application-service-overwrites) 
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

Go to the directory where you've put `docker-compose.yml`.

Copy the environment file `.env.example` inside the directory and rename it to `.env`. 

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

When running `docker-compose up` all services Kitodo.Production (APP), Database (DB), Elastic Search (ES) and Active MQ (MQ) in our `docker-compose.yml` will be started and each as seperate Docker container.

### Environment file

To configure our services copy the environment file `.env.example` inside the directory and rename it to `.env`. Adjust the configuration of the respective service to suit your needs. The variables are marked with the prefix of the service e.g. `APP_` for our Kitodo.Production Application.

### Application Service Overwrites

In the folder overwrites are configurations to overwrite our default Kitodo.Production configuration of `docker-compose.yml`. 

For example to build image with specific Git branch and run Tomcat in debug mode use following `docker-compose` command with parameters.

```
docker-compose -f docker-compose.yml -f ./overwrites/docker-compose-app-builder-git.yml -f ./overwrites/docker-compose-app-debug.yml up -d --build
```

### Using the log viewer service

The logs of the respective container can be accessed via the following command:

```
docker logs CONTAINER
```

It is more convenient to use the log viewer service "Dozzle" with the following overwrite: 

```
docker-compose -f docker-compose.yml -f ./overwrites/docker-compose-logviewer.yml up -d
```

#### Builder

The builder defines the source to get the resources to create the image. The builder provides a preset to customize the appropriate builder using the `.env` file.

You can only overwrite the default `docker-compose.yml` with one of these builder overwrites.

##### Release

Release files of any [release of Kitodo.Production](https://github.com/kitodo/kitodo-production/releases) will be used to build Kitodo.Production image.

The variables of the Release Builder can be found in the `.env` file with the prefix `APP_BUILDER_RELEASE_`.

```
docker-compose -f docker-compose.yml -f ./overwrites/docker-compose-app-builder-release.yml up -d --build
```

##### Git

Archive with specified commit / branch and source url will be downloaded. Futhermore builder triggers maven to build sources, creates database using temporary database and migrate database using flyway migration steps.

The variables of the Git Builder can be found in the `.env` file with the prefix `APP_BUILDER_GIT_`.

```
docker-compose -f docker-compose.yml -f ./overwrites/docker-compose-app-builder-git.yml up -d --build
```

##### Local

Local WAR, SQL and ZIP files will be used to build Kitodo.Production image.

The variables of the Local Builder can be found in the `.env` file with the prefix `APP_BUILDER_LOCAL_`.

```
docker-compose -f docker-compose.yml -f ./overwrites/docker-compose-app-builder-local.yml up -d --build
```

#### Debug

This overwrite configures tomcat to run in debug mode after building and when starting container.

The variables of the debug overwrite file can be found in the `.env` file with the prefix `APP_DEBUG_`.

```
docker-compose -f docker-compose.yml -f ./overwrites/docker-compose-app-debug.yml up -d
```

#### Dev

This overwrite overwrites WAR file and bind local one at runtime. 

```
docker-compose -f docker-compose.yml -f ./overwrites/docker-compose-app-dev.yml up -d
```

If you go into the container (with `docker exec -it CONTAINERNAME bash`) the tomcat can be restarted with the new application using the command `/deploy.sh`.


## Structure

There are two serveral ways to structure the Compose Project.

### Single compose project

If only one project instance is needed or repository is used e.g. as submodule in other projects.

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

### Multi compose project

When different projects are needed e.g. to do a review without breaking the existing environment for the current projects of a customer and a feature.

Go to the directory where you've put docker-compose.yml. Create subdirectory where you want to store your compose projects.
In our examples we named it "projects". Create project directory (e.g. my-compose-project) in subdirectory where you want to store your compose project data.

#### Usage with env file in project folder 

Copy the `.env.example` to project directory, rename file to `.env` and change value of `COMPOSE_PROJECT_NAME` env to the name of project directory and comment out the single compose project variables and uncomment the multiple compose project variables

```
docker-compose --env-file ./projects/my-compose-project/.env ... # ... means command e.g. up -d --build
```

#### Usage with one env file in base folder and project name parameter 

Copy `.env.example`, rename file to `.env`, uncomment `COMPOSE_PROJECT_NAME` and comment out the single compose project variables and uncomment the multiple compose project variables

```
docker-compose -p my-compose-project ... # ... means command e.g. up -d --build
```
