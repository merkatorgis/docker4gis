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
  - [On the server](#on-the-server)
- [Testing things](#testing-things)
  - [Unit tests](#unit-tests)
  - [Integration tests](#integration-tests)
  - [Build and run](#build-and-run)
  - [Bash Automated Testing System](#bash-automated-testing-system)
- [Base images](#base-images)
- [Other topics](#other-topics)

## The general idea

### Docker

Docker runs _containers_ from _images_. Containers are processes running in a
separate computing environment, as if they were started in a freshly created
virtual machine, dedicated to that specific process. As a container, the process
is running in the same predifined context each and every time. That context is
defined in a Docker _image_, that is stored in a Docker _registry_. Whether the
container runs on your development laptop, on your staging server, or on your
production server, if it's started from the same image, it'll run in the same
context. This way, apps gain a great level of baked-in robustness and
predictability, which are great enablers for  extension and improvement.

### docker4gis

A docker4gis app/website consists of several Docker images, from which
interconnected containers are run behind a reverse proxy HTTPS gateway
container, eg
```
                  | - app
                  |
                  | - api
browser - proxy - |    |
                  | - postgis
                  |    |
                  | - geoserver
```
The docker4gis repo provides base images, the scripts to build and run them, as
well as extend them, and a common interface to all this, called the [_main
script_](#building-things)


## Getting started

### Development environment

A development environment requires:

- [Docker](https://docs.docker.com/install/)
- Bash - the default terminal on Mac and most Linuxes. On windows, install [Git
  for Windows](https://gitforwindows.org/) to get Git Bash.
- [GitHub Desktop](https://desktop.github.com/) (or just the git command line
  tools)
- A code oriented text editor (Atom, Sublime Text, Visual Studio Code, or maybe
  you're a fan of vi or Emacs, anything like these would work).

On Windows, Docker requires Windows 10 Professional or Enterprise (the Home
edition won't work), and you need 16 GB of RAM. If this poses any hurdles, take
a look at our guide for setting up a [Cloud development
environment](clouddevenv.md). Also, on Windows, make sure you get LF line
endings, instead of CRLF; issuing `git config --global core.autocrlf false`
before cloning the repo should do the trick.

### Fork

Create a fork*) of [the main docker4gis
repo](https://github.com/merkatorgis/docker4gis) & clone your fork locally with
GitHub Desktop.

### Setup app directory

Create a directory for your app's code on your local file system. Make a
directory `docker` inside it. Copy the template [main script](/templates/main)
to this `docker` directory.

Rename the main script to a short name for your specific app (your're going to
type that name quite a lot in the terminal). Then edit the main script to set
the `DOCKER_USER` variable. If you're on a specific Docker registry, set the
`DOCKER_REGISTRY` variable as well. Edit the `DOCKER_BASE` value to point to the
[base](/base) directory in your fork's local clone (or configure this variable
in your Bash profile).

## Building things

See the different [base images](#base-images) for their features and how to set
them up for your app. Mostly, you'd copy a template `Dockerfile` and `build.sh`
script, and optionally add things you need.

Then, use your _main script_ to build things, eg `./app build proxy` to build
your app's proxy image

## Running things

`./app run` will run your app in your development environment. It will also run
any integration tests.

Where `./app run` creates containers from images (or starts existing
containers), `./app stop` will stop all the app's containers.

When you're happy about your changes to a specific component, save a version to
the Docker registry with `./app push {component} {tag}`. The registry can be the
Docker Hub, or any other public or private registry. The docker4gis `registry`
base image facilitates setting up a private registry.

When working on a project with several colleagues, all will have their focus on
different components. You don't need to constantly build all the images; instead
you can update all at once to the most recently pushed version through `./app
latest`. That will remove all existing containers, update all images, and then
run everything. To store a newly built, but not yet versioned image of a
specific component, use `./app push {component}` (without any tag).

### On the server

Once your images are in a registry, they're accessible there from your servers.
On a server, the images are never built, only run. So the only thing you need
there, is the little run script that runs the package.

On the server, run:
```
docker container run --rm {DOCKER_REGISTRY}{DOCKER_USER}/package:{tag} > {DOCKER_USER}
```
e.g.
```
docker container run --rm docker.example.com/theapp/package:237 > theapp
```
Then, make it executable: `chmod +x theapp` and edit the needed environment
values.

When you run it, pass a specific tag, and it will pull the images from the
registry, and run the containers. So the example is run like:
```
./theapp 237
```

Note that you might need to login to your registry first.

## Testing things

### Unit tests

To run a component's [unit tests](https://en.wikipedia.org/wiki/Unit_testing),
use the test action, eg `./app test proxy`. This will do zero or more of two
things:

- Run any `test.sh` command(s) in the component directory, if present.
- Run any [BATS](https://github.com/bats-core/bats-core) tests in the component
  directory, if present (see [below](#bash-automated-testing-system)).

### Integration tests

To run the application's [integration
tests](https://en.wikipedia.org/wiki/Integration_testing), use the test action
without a component parameter, eg `./app test`. This will do the same zero or
more of two things as with the unit testing, except that it will skip any
component directories, and look in the (optional) `test` directory instead.

### Build and run

Any unit tests are run automatically before building a component with `./app
build {component}` - _if any test fails, the build is canceled_.

And since in practise, you'll repeatedly want to see a successfully built image
running your recent changes, and check if everything is ok, there is this
"build, run, and test" action: `./app br {component}`; it's really just a
schortcut for `./app build {component} && ./app run`.

### Bash Automated Testing System

Running BATS tests is integrated in docker4gis, but it depends on a local
installation of the BATS software, which the test runner will try to install for
you through [NPM](https://www.npmjs.com/package/bats), if available.

#### Helper

You'll want to include the common [helper file](../base/test_helper/load.bash)
like this:
```bash
#!/usr/bin/env bats
load "$DOCKER_BASE"/test_helper/load.bash
```
This will load the [bats-assert](https://github.com/bats-core/bats-assert) and
[bats-file](https://github.com/bats-core/bats-file) modules.

Also, it exposes a `$cmd` variable holding the "command under test", presuming
the current `.bats` test file has the same name and location as the command
file, except for the extra .bats suffix.

#### Plugin

In any bash commands under test, you'll want to include the [bats plugin
file](../base/.plugins/bats/.bats.bash) like this (the test runner installs it
in your home directory):
```bash
#!/bin/bash
# shellcheck source=/dev/null
source ~/.bats.bash
```

##### Subroutines

This plugin provides the `@sub` function as a means to break up shell scripts in
small testable subroutines, eg:
```bash
#!/bin/bash
ID=$1

LOADER_ROOT_DIR=${LOADER_ROOT_DIR:-"/fileport/$DOCKER_USER"}

# shellcheck source=/dev/null
source ~/.bats.bash

@sub 1 check_running "$(basename "$0")"

@sub 2 dir "$LOADER_ROOT_DIR"
dir="${output:?}"

klicmeldnr=$(ls "$dir"/extracted)
echo "$ID $klicmeldnr converting in $dir ..."
@sub 3 run_loader "$dir"
echo "$ID $klicmeldnr converting in $dir finished with status $output"
```

Parameters to the `@sub` function are:

1. The nonzero error number your script should exit with if the subroutine
   fails.
1. The basename of a script file named `sub/{basename}.sh` relative to the
   current script's location.
1. Any parameters to call the subcommand with.

Any output of a successful subroutine is available in the `$output` variable.
The error code of the actual subcommand is available in `$status`.

(The `:?` suffix in the sample above, causing the command to fail if the
`$output` variable is not defined, is there to tell
[shellcheck](https://www.shellcheck.net/) we _know_ it's there.)

In case the main script needs to survive a failing subroutine, use `@subvive`
instead of `@sub`, eg:
```bash
...
if @subvive 1 daytime; then
    timestring=${output:?}
    daytime=true
fi
...
```


##### Validations

In the subroutine scripts, include the plugin as well, and make generously use
of its myriad of assertion functions to validate input parameters, eg:
```bash
#!/bin/bash
...
# shellcheck source=/dev/null
source ~/.bats.bash
assert_readable_file file "$file"
assert_integer_min MAX_BYTES "$MAX_BYTES" 0
assert_integer_min_max_length MIN_TIME_H "$MIN_TIME_H" 00 23 2
assert_integer_min_max_length MIN_TIME_M "$MIN_TIME_M" 00 59 2
assert_integer_min_max_length MAX_TIME_H "$MAX_TIME_H" 00 23 2
assert_integer_min_max_length MAX_TIME_M "$MAX_TIME_M" 00 59 2
assert_integer_min_max_length cur_time "$cur_time" 0000 2359 4
...
```
Any violated assertion will make the script fail with error 22 EINVAL, using the
given name and value in the error message. So from a `.bats` test script, use
`assert_failure 22` to test for proper input invalidation, eg:
```bash
#!/usr/bin/env bats
load "$DOCKER_BASE"/test_helper/load.bash
...
@test 'string MAX_BYTES' {
    export MAX_BYTES=aa
    run "$cmd" "$file"
    assert_failure 22
}
@test 'negative MIN_TIME_H' {
    export MIN_TIME_H=-1
    run "$cmd" "$file"
    assert_failure 22
}
...
```
(Note that these tests use the [helper](#helper) `$cmd` variable.)

## Base images 

- cron
- elm
- gdal
- geoserver
- mapserver
- mapproxy
- glassfish
- tomcat (build from maven)
- mapfish
- postfix
- mysql
- [postgis](postgis.md)
- postgis-gdal
- postgrest
- swagger
- [proxy](proxy.md)
- registry
- serve

## Other topics

- plugins
- certificates
- [Cloud development environment](clouddevenv.md)

*) fork & merkatorgis:
- If you fix, extend, or otherwise improve things, please create a pull request,
  so that it can be merged into the originating merkatorgis/docker4gis
  repository.
- When you want to update your fork with new "upstream" changes from
  merkatorgis/docker4gis, use the `compare` function on GitHub:
  https://github.com/${your_account}/docker4gis/compare/master...merkatorgis:master
