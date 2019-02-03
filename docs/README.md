# docker4gis documentation

## The general idea

### Docker

Docker runs __containers__ from __images__. Containers are processes running in a separate computing environment, like the're started in a freshly created virtual machine dedicated to that specific process. So as a container, the process is running in the same predifined context each and every time. The context is defined in a Docker __image__, that is stored in a __registry__. Whether the container runs on your development laptop, or on your staging server, or on your production server, if it's started from the same image, it'll run in the same context. This way, apps gain a great level of baked-in robustness and predictability, which are great enablers for  extension and improvement.

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
The docker4gis repo provides base images, the scripts to build and run them, and extend then, and a common interface called the [__main script__](#building_things)


## Getting started

### Development environment

A development environment requires:

- [Docker](https://docs.docker.com/install/)
- Bash - the default terminal on Mac and most Linuxes. On windows, install [Git for Windows](https://gitforwindows.org/) to get Git Bash.
- [GitHub Desktop](https://desktop.github.com/) (or just the git command line tools)
- A code oriented text editor (Atom, Sublime Text, Visual Studio Code, or maybe you're a fan of vi or Emacs, anything like these would work).

On Windows, Docker requires Windows 10 Professional or Enterprise (the Home edition won't work), and you need 16 GB of RAM. If this poses any hurdles, take a look at our guide for setting up a [Cloud development environment](clouddevenv.md).

### Fork

Create a fork of [the main dockedr4gis repo](https://github.com/merkatorgis/docker4gis) & clone your fork locally with GitHub Desktop.

### Setup app directory

Create a directory for your app on your local file system. Make a directory `Docker` inside it. Copy the template [run](/templates/run) directory and the template [main script](/templates/script/app) to this `Docker` directory.

Rename the main script to a short name for your specific app. Then edit the main script to set the `DOCKER_USER` variable. If you're on a specific Docker registry, set the `DOCKER_REGISTRY` variable as well. Edit the `DOCKER_BASE` value to point to the [base](/base) directory in your fork's local clone (or configure this variable in your bash profile).

Make your main script executable with `chmod +x app` (where app it the script's filename).

## Building things

See the different [base images](#base_images) for their features and how to set them up for your app. Mostly, you'd copy a template `Dockerfile` and `build.sh` script, and optionally add things you need.

Then, use your __main script__ to build things, eg `./app build proxy` to build your app's proxy image

## Running things

Read about the [run image](run.md).

When you've built all your images __and__ the `run` image, `./app run` will run your app. That is, it'll run the `latest` version of it; see the [run image](run.md) docs for details about versioning.

Where `./app run` creates containers from images, `./app stop` will stop all the app's containers, and `./app start` will start existing (stopped) containers.

When you're happy about an image, you can `docker image push` it to a Docker registry. This can be the Docker Hub, or any other public or private registry. The docker4gis `registry` base image facilitates setting up a private registry.

Once your images are in a registry, they're accessible there from your servers. On a server, the images are never built, only run. So the only thing you need there, is the little run script that runs the run image. See its [docs](run.md) for details.

## Base images 

- cron
- elm
- gdal
- geoserver
- glassfish
- mapfish
- postfix
- postgis
- postgis-gdal
- [proxy](proxy.md)
- registry
- serve

## Other topics

- plugins
- certificates
- [Cloud development environment](clouddevenv.md)
