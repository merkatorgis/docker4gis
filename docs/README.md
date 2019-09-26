# docker4gis documentation

## Table of contents

- [The general idea](#the-general-idea)
  - [Docker](#docker)
  - [docker4gis](#docker4gis)
- [Getting started](#getting-started)
  - [Development environment](#development-environment)
  - [Fork](#fork)
  - [Setup app directory](#setup-app-directory)
- [Building things](#building-things)
- [Running things](#running-things)
- [Base images](#base-images)
- [Other topics](#other-topics)

## The general idea

### Docker

Docker runs _containers_ from _images_. Containers are processes running in a separate computing environment, as if they were started in a freshly created virtual machine, dedicated to that specific process. As a container, the process is running in the same predifined context each and every time. That context is defined in a Docker _image_, that is stored in a Docker _registry_. Whether the container runs on your development laptop, on your staging server, or on your production server, if it's started from the same image, it'll run in the same context. This way, apps gain a great level of baked-in robustness and predictability, which are great enablers for  extension and improvement.

### docker4gis

A docker4gis app/website consists of several Docker images, from which interconnected containers are run behind a reverse proxy HTTPS gateway container, eg
```
                  | - app
                  |
                  | - api
browser - proxy - |    |
                  | - postgis
                  |    |
                  | - geoserver
```
The docker4gis repo provides base images, the scripts to build and run them, as well as extend them, and a common interface to all this, called the [_main script_](#building-things)


## Getting started

### Development environment

A development environment requires:

- [Docker](https://docs.docker.com/install/)
- Bash - the default terminal on Mac and most Linuxes. On windows, install [Git for Windows](https://gitforwindows.org/) to get Git Bash.
- [GitHub Desktop](https://desktop.github.com/) (or just the git command line tools)
- A code oriented text editor (Atom, Sublime Text, Visual Studio Code, or maybe you're a fan of vi or Emacs, anything like these would work).

On Windows, Docker requires Windows 10 Professional or Enterprise (the Home edition won't work), and you need 16 GB of RAM. If this poses any hurdles, take a look at our guide for setting up a [Cloud development environment](clouddevenv.md).
Also, on Windows, make sure you get LF line endings, instead of CRLF; issuing `git config --global core.autocrlf false` before cloning the repo should do the trick.

### Fork

Create a fork*) of [the main docker4gis repo](https://github.com/merkatorgis/docker4gis) & clone your fork locally with GitHub Desktop.

### Setup app directory

Create a directory for your app's code on your local file system. Make a directory `docker` inside it. Copy the template [.package](/templates/.package) directory and the template [main script](/templates/main) to this `docker` directory.

Rename the main script to a short name for your specific app (your're going to type that name quite a lot in the terminal). Then edit the main script to set the `DOCKER_USER` variable. If you're on a specific Docker registry, set the `DOCKER_REGISTRY` variable as well. Edit the `DOCKER_BASE` value to point to the [base](/base) directory in your fork's local clone (or configure this variable in your Bash profile).

Make your main script executable with `chmod +x app` (where app it the script's file name).

## Building things

See the different [base images](#base-images) for their features and how to set them up for your app. Mostly, you'd copy a template `Dockerfile` and `build.sh` script, and optionally add things you need.

Then, use your _main script_ to build things, eg `./app build proxy` to build your app's proxy image

## Running things

When you've built all your images, create a runnable package with `./app package`, then `./app run` will run your app. That is, it'll run the `latest` version of it; see the [package](package.md) docs for details about versioning.

Where `./app run` creates containers from images (start existing containers), `./app stop` will stop all the app's containers.

When you're happy about your changes, save a version to the Docker registry with `./app package {tag}`. This can be the Docker Hub, or any other public or private registry. The docker4gis `registry` base image facilitates setting up a private registry.

Once your images are in a registry, they're accessible there from your servers. On a server, the images are never built, only run. So the only thing you need there, is the little run script that runs the package. See its [docs](package.md) for details.

## Base images 

- cron
- elm
- gdal
- geoserver
- glassfish
- tomcat (build from maven)
- mapfish
- postfix
- [postgis](postgis.md)
- postgis-gdal
- [proxy](proxy.md)
- registry
- serve

## Other topics

- plugins
- certificates
- [Cloud development environment](clouddevenv.md)

*) fork & merkatorgis:
- If you fix, extend, or otherwise improve things, please create a pull request, so that it can be merged into the originating merkatorgis/docker4gis repository.
- When you want to update your fork with new "upstream" changes from merkatorgis/docker4gis, use the `compare` function on GitHub: https://github.com/${your_account}/docker4gis/compare/master...merkatorgis:master
