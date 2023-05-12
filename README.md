# Kitodo.Production Docker

 * [Prerequisites](#prerequisites)
 * [Quickstart](#quickstart)
 * [Services](#services)
   * [Environment file](#environment-file) 
   * [Compose overwrites](#compose-overwrites) 
   * [Hooks to extend and overwrite app data](#hooks-to-extend-and-overwrite-app-data) 
 * [Structure](#usage)
   * [Single compose project](#single-compose-project)
   * [Multi compose project](#multi-compose-project)
 * [Makefile](#makefile)
 * [Workflow to build and run Kitodo.Production over ngrok](#workflow-to-build-and-run-kitodoproduction-over-ngrok)

With the docker image provided, Kitodo.Production can be started in no time at all. A MySQL/MariaDB database and ElasticSearch must be present to start the application. There is also a Docker Compose file for a quick start.

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
docker compose up -d --build
```

Stops all service containers
```
docker compose stop
```

Stops and remove all service containers
```
docker compose down
```

## Services

When running `docker compose up` all services Kitodo.Production (APP), Database (DB), Elastic Search (ES) and Active MQ (MQ) in our `docker-compose.yml` will be started and each as separate Docker container.

### Environment file

To configure our services copy the environment file `.env.example` inside the directory and rename it to `.env`. Adjust the configuration of the respective service to suit your needs. The variables are marked with the prefix of the service e.g. `APP_` for our Kitodo.Production Application.

### Compose overwrites

In the folder overwrites are configurations to overwrite our default Kitodo.Production configuration of `docker-compose.yml`. 

For example to build image with specific Git branch and run Tomcat in debug mode use following Docker Compose command with parameters.

```
docker compose -f docker-compose.yml -f ./overwrites/docker-compose-app-builder-git.yml -f ./overwrites/docker-compose-app-debug.yml up -d --build
```

#### Builder

The builder defines the source to get the resources to create the image. The builder provides a preset to customize the appropriate builder using the `.env` file.

You can only overwrite the default `docker-compose.yml` with one of these builder overwrites.

##### Release

Release files of any [release of Kitodo.Production](https://github.com/kitodo/kitodo-production/releases) will be used to build Kitodo.Production image.

The variables of the Release Builder can be found in the `.env` file with the prefix `APP_BUILDER_RELEASE_`.

```
docker compose -f docker-compose.yml -f ./overwrites/docker-compose-app-builder-release.yml up -d --build
```

##### Git

Archive with specified commit / branch and source url will be downloaded. Furthermore, builder triggers maven to build sources, creates database using temporary database and migrate database using flyway migration steps.

The variables of the Git Builder can be found in the `.env` file with the prefix `APP_BUILDER_GIT_`.

```
docker compose -f docker-compose.yml -f ./overwrites/docker-compose-app-builder-git.yml up -d --build
```

##### Local

Local WAR, SQL and ZIP files will be used to build Kitodo.Production image.

The variables of the Local Builder can be found in the `.env` file with the prefix `APP_BUILDER_LOCAL_`.

```
docker compose -f docker-compose.yml -f ./overwrites/docker-compose-app-builder-local.yml up -d --build
```

#### Debug

This configures tomcat to run in debug mode after building and when starting container.

The variables of the debug overwrite file can be found in the `.env` file with the prefix `APP_DEBUG_`.

```
docker compose -f docker-compose.yml -f ./overwrites/docker-compose-app-debug.yml up -d
```

#### Dev

This overwrites WAR file and bind local one at runtime. 

```
docker compose -f docker-compose.yml -f ./overwrites/docker-compose-app-dev.yml up -d
```

If you go into the container (with `docker exec -it CONTAINERNAME bash`) the tomcat can be restarted with the new application using the command `/deploy.sh`.

#### Log Viewer 

The logs of the respective container can be accessed via the following command:

```
docker logs CONTAINER
```

It is more convenient to use the log viewer service "Dozzle" with the following overwrite: 

```
docker compose -f docker-compose.yml -f ./overwrites/docker-compose-logviewer.yml up -d
```

#### File Browser 

File Browser provides a file managing interface for Kitodo.Production config and data directories. It can be used to upload, delete, preview, rename and edit files of these directories.

```
docker compose -f docker-compose.yml -f ./overwrites/docker-compose-filebrowser.yml up -d
```

### Hooks to extend and overwrite app data

There are some hooks available to modify and extend default data when running Kitodo.Production container for the first time. 

#### Modify container before startup

This hook runs before startup.sh is executed. For example, you can add some SSH configuration here.

```
      - type: bind
        source: ...
        target: /usr/bin/before_startup.sh
```

#### Modify data directory

All files and subdirectories of directory bind to `/tmp/kitodo/overwrites/data` are copied to the `/usr/local/kitodo` folder. For example, you can overwrite default ruleset files or add your custom ruleset files to ruleset folder.

```
      - type: bind
        source: ...
        target: /tmp/kitodo/overwrites/data
```

Under `/overwrites/app` we implemented these mechanism, so you can add the files and directories to modify your project. This hook is especially helpful when you want to a first basic configuration for your [multi compose project](#multi-compose-project).

#### Modify config directory

All files and subdirectories of directory bind to `/tmp/kitodo/overwrites/config` are copied to the `/usr/local/tomcat/webapps/kitodo/WEB-INF/classes` folder. For example, you can overwrite default `kitodo_config.properties`, add your log4j2 config to `log4j2.xml` or add file formats with adjusting `kitodo_fileFormats.xml`. 

```
      - type: bind
        source: ...
        target: /tmp/kitodo/overwrites/config
```

#### Modify database after initialisation

This hook runs after database is initialized. For example, you can add import configurations for your custom catalogues or example data for development purposes to database.

```
      - type: bind
        source: ...
        target: /tmp/kitodo/overwrites/sql/post_init.sql
```

## Structure

There are two several ways to structure the Compose Project.

### Single compose project

If only one project instance is needed or repository is used e.g. as submodule in other projects.

Build image before and start the container of image
```
docker compose up -d --build
```

Stops the container
```
docker compose stop
```

Stops and remove the container
```
docker compose down
```

### Multi compose project

When different projects are needed e.g. to do a review without breaking the existing environment for the current projects of a customer and a feature.

Go to the directory where you've put docker-compose.yml. Create subdirectory where you want to store your compose projects.
In our examples we named it "projects". Create project directory (e.g. my-compose-project) in subdirectory where you want to store your compose project data.

#### Project specific Docker Compose file

Add compose file with name `docker-compose.yml` to your project directory and maybe add this as config file to overwrite them all with your project specific settings.

```
docker compose ... -f ./projects/my-compose-project/docker-compose.yml 
```

When using our [Make](#makefile) the compose file is added automatically as last file to `COMPOSE_FILE` variable of Makefile so it overwrites existing configs.

#### Project specific environment file

Copy the `.env.example` to project directory, rename file to `.env` and change value of `COMPOSE_PROJECT_NAME` env to the name of project directory and comment out the single compose project variables and uncomment the multiple compose project variables

```
docker compose --env-file ./projects/my-compose-project/.env ... # ... means command e.g. up -d --build
```

#### General enviroment file (same config for projects)

Copy `.env.example`, rename file to `.env`, uncomment `COMPOSE_PROJECT_NAME` and comment out the single compose project variables and uncomment the multiple compose project variables

```
docker compose -p my-compose-project ... # ... means command e.g. up -d --build
```

## Makefile

To facilitate the use of Docker Compose, the Makefile can be used. It takes care of the creation of the project folder and provides various targets to manage the Compose project.

For more information use the following command:

```
make help
```

## Workflow to build and run Kitodo.Production over ngrok

If you want to build and run Kitodo.Production from a specific branch of a repository fork or the base repository e.g. to perform a review or a visual test, then you are in the right place.

This repository contains a workflow with the help of which you can brew and launch Kitodo.Production. Via ngrok you can then access Kitodo.Production, the log viewer and the file browser via a URL.

To do this you have to fork this repository, register with ngrok and set the Auth token of ngrok as repository secret (Settings -> Secrets and variables -> Action -> New repository secret) with the name `NGROK_AUTH_TOKEN`.

Under Actions of fork repository you will find the workflow `Build and run Kitodo.Production over ngrok`. With click on that workflow a page with last workflow runs will be opened. When you click the button `Run workflow` following popup will be displayed.

![image](https://github.com/slub/kitodo-production-docker/assets/3832618/36cfa283-2a51-43b7-bf7f-857f65738581)

As default the `master` branch of base Kitodo.Production repository will be used. Adjust the branch and repository inputs and click on `Run workflow`. If everything works out, Kitodo.Production will be built and launched against this repository and branch. This takes a few minutes. 

When the workflow step `Run ngrok` is active, navigate to [ngrok Dashboard and open the agents](https://dashboard.ngrok.com/tunnels/agents) and click on the active agent.

![image](https://github.com/slub/kitodo-production-docker/assets/3832618/b96debe4-1b76-43dc-903e-cda4d1dae4c0)

In the panel you will see all exposed ports (Kitodo.Production for 8080, Log Viewer for 8088 and the File Browser 8090) mapped to a ngrok URL's. Click on the URL to navigate to the appropriate application and click on `Visit Site`. Don't forget to add the slug `/kitodo` to the Kitodo.Production URL.

The stop the workflow navigate to [ngrok Dashboard and open the agents](https://dashboard.ngrok.com/tunnels/agents) again and click the stop icon on the active agent and confirm this with the click `Stop session` in the displayed popup.

