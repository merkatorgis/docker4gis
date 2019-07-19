# run package

To run your application, you need its `package` image. It contains all the specific run scripts and configurations to start the different containers needed.

Tagging the package with a version label lets you start specific versions of your application.

## Getting started

Copy the [`templates/.package`](/templates/.package) directory to your application's `docker` directory.

## Building

Use your app's main script, eg. `./app package` to build the package image. This gets you a `latest`-tagged package image, that starts the `latest` version of all different application images.

### Tagging

To save a specific version of an application, do `./app package {tag}`. This wil tag all images with the tag provided, and save them in the Docker registry.

I.e. when you build an image, you get a `latest` version of it. On tagging the package, it will tag the local `latest` versions of all images in the project, and push the tagged _and_ the `latest` images to the registry.

The `package` image is treated slightly different: the `latest` package will always run all `latest` versions; a tagged package will run all tagged images. On tagging, both the latest and the tagged package image are pushed to the registry as well.

## Running

### Local development environment

Use your app's main script: `./app run` will start the `latest` version of your application, `./app run 627` starts version `627`.

#### Build & run

To build an image and then run it in one go, use `./app br {component}` eg. `./app br proxy` builds the latest proxy image and runs the latest package.

### Server

All a server needs is Docker, access to the Docker registry, and the little run script to run the package.

- Copy `.package/run.sh` to the server, eg. `~/apprun`.
- Edit it to set environment variable `DOCKER_USER` 
- Make it executable through `chmod +x ~/apprun`

`cd ~`, then `./apprun` for latest, `./apprun 627` for version 627.
Any image version not found locally on the server, will be pulled from the Docker registry automatically.
