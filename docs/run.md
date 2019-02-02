# run application image

To run your application, run your run image. It contains all the specific run scripts and configurations to start the different containers needed.

Tagging your run images with a version label lets you start specific versions of your application.

## Getting started

Copy this [`templates/run`](/templates/run) directory to your application's `Docker` directory.

## Customising

In `build.sh`, comment out the lines starting containers you don't need, eg
```
	# export DOCKER_REPO='mapfish'
	# export DOCKER_TAG="$MAPFISH_TAG"
	# "${here}/scripts/mapfish/run.sh"
```

## Building

Use your app's main script, eg `./app build run` to use the `latest` tag for the run images and all others.

For a version-tagged run image: `./app build run 627`

To use specific versions of the actual application images, specify environment variables, eg:
```
APP_TAG=193 POSTGIS_TAG=12 ./app/build run 628
```

## Running

### Local development environment

Use your app's main script: `./app run` will start the `latest` version of your application, `./app run 627` starts version `627`.

#### Build & run

To build the run image and then run in one go, use `./app br run`. This works for any other image as well, eg `./app br proxy` builds the proxy image and runs the latest run image (`./app br proxy 27` would build proxy:27 and run run:latest, whereas `./app br run 8` would work, but not make sense).

### Server

Use the app's run script (which is a copy of `run/run.sh`): `./apprun` for latest, `./apprun 628` for version 628 with app 193 & postgis 12.
Any image version not found locally on the server, will be pulled from the Docker registry automatically.
