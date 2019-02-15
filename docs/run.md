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

To use specific versions of the application images, specify tags in environment variables, eg:
```
APP_TAG=193 POSTGIS_TAG=12 ./app build run
```

Then, to tag that run image with a specific version:
```
./app tag 627 run
```

## Running

### Local development environment

Use your app's main script: `./app run` will start the `latest` version of your application, `./app run 627` starts version `627`.

#### Build & run

To build the run image and then run in one go, use `./app br run`. This works for any other image as well, eg `./app br proxy` builds the proxy image and runs the latest run image.

#### Push

When things work, use `docker image push` to store the run image in the Docker registry.

As a convenience, the pushing can be done directly when tagging, through `./app tag -push {tag} {image}`, eg: `./app tag -push 627 run` to tag run:latest as run:627, push run:latest, and push run:627.

### Server

All a server needs is Docker, access to the Docker registry, and the little run script to run the run image.

- Copy `run/run.sh` to the server, eg `~/apprun`.
- Edit it to set environment variable `DOCKER_USER` 
- Make it executable through `chmod +x ~/apprun`

`cd ~`, then `./apprun` for latest, `./apprun 627` for version 627 with app 193 & postgis 12.
Any image version not found locally on the server, will be pulled from the Docker registry automatically.
