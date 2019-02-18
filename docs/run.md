# run application image

To run your application, run your run image. It contains all the specific run scripts and configurations to start the different containers needed.

Tagging your run images with a version label lets you start specific versions of your application.

## Getting started

Copy the [`templates/run`](/templates/run) directory to your application's `docker` directory.

## Customising

In `build.sh`, comment out the lines starting containers you don't need, eg
```
	# export DOCKER_TAG="$MAPFISH_TAG"
	# "${here}/scripts/mapfish/run.sh"
```

## Building

Use your app's main script, eg `./app build run` to build the run image. This gets you a `latest`-tagged run image, that starts the `latest` version of all different application images.

### Tagging

To tag a specific version of an application image, use the main script's `tag` action, eg:
```
./app tag app 193
./app tag postgis 12
```

To build a specific version of the run image, that runs specific versions of the application images, eg:
```
APP_TAG=193 POSTGIS_TAG=12 ./app build run 627
```

This leaves your `run:latest` untouched (starting `app:latest` and `postgis:latest`), and yields an extra `run:627` starting `app:193` and `postgis:12`.

## Running

### Local development environment

Use your app's main script: `./app run` will start the `latest` version of your application, `./app run 627` starts version `627`.

#### Build & run

To build the run image and then run in one go, use `./app br run`. This works for any other image as well, eg `./app br proxy` builds the proxy image and runs the latest run image.

#### Push

When things work, use `docker image push` to store the images in the Docker registry, eg `docker image push ourapp/run:latest`, or `docker image push docker.itsus.com/com/ourapp/postgis:12`.

As a convenience, the pushing can be done directly when tagging, through `./app tag -push {tag} {image}`, eg: `./app tag -push 12 postgis` to tag postgis `latest` as postgis `12`, push postgis `latest`, and push postgis `12`. Use this for application images. Push the run image by hand, so that `./app run` predictably starts the `latest` of everything.

### Server

All a server needs is Docker, access to the Docker registry, and the little run script to run the run image.

- Copy `run/run.sh` to the server, eg `~/apprun`.
- Edit it to set environment variable `DOCKER_USER` 
- Make it executable through `chmod +x ~/apprun`

`cd ~`, then `./apprun` for latest, `./apprun 627` for version 627 with app 193 & postgis 12.
Any image version not found locally on the server, will be pulled from the Docker registry automatically.
