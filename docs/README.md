# docker4gis documentation

How the "new" things work:

New as in:

- docker4gis as an npm package (automatic installation through
  [npx](https://www.npmjs.com/package/npx));
- components as seperate git repos;
  - supporting pipelines in the git hosting environment.

## Setup new project

### Package

Clone your project's Git repo, cd into its root, and run 
```
  npx --yes docker4gis@latest init
```
It will ask you which docker registry to use, how the application is called,
and whether you want to create an "alias" (if you don'thave it already) for the
docker4gis command (so that you can type e.g. `dg init` instead of `npx --yes
docker4gis@latest init`).

This _package_ repo is to manage the application's package image, which is used
to run a specific version of the application, with all the specific versions of
the application's different components.

### Components

The application's "components" are the different containers that comprise the
running application: proxy, app, api, database, geoserver, etc.

To add a component: create another repo for it, clone the component repo _as a
sibling of the package directory_ (this is important), cd into its root, and run
```
  dg component
```
(assuming you had the docker4gis alias created with its default
name). It will ask you how to call the component, which base docker4gis
component it should extend, and which version of the base component to use
(default is `latest`). If the base component has multiple "flavours", the
flavours are listed, and you're asked to choose one.

The available docker4gis base components all reside in their proper repo under
[https://github.com/merkatorgis/docker4gis-{name}](https://github.com/merkatorgis/docker4gis-{name}),
e.g. [proxy](https://github.com/merkatorgis/docker4gis-proxy).

## Build and run

From a component directory, you can build its image by issuing `dg build`. When
all components are built, you can run the application with `dg run`.

When you make a change to a component, and want to see its effect, you can build
the component's image and run the application with the new image in one go,
using `dg br` (for build & run).

Note that you can pass the component name (or `package`) to build the image from
a sibling directory, e.g. `dg build app`, or `dg br proxy`.

## Push

When you're happy with the changes you made to a component, and you've seen it
running successfully, you should _push_ it by running `dg push` from the
component directory.

This will push the new image to the Docker registry (presuming you have logged
in using `docker login`), write a version file to the repo, containing an
incremented integer version number (starting by 1), tag the git repo with
`v-{version_number}`, commit the changes, and push them to `origin`.

## Build the package

Each time you `dg run` the application, the package directory is updated with
the current component version numbers, which are read from the version files
that `dg push` generates. For components that haven't been pushed yet, a version
`latest` is listed in the package directory.

Once all components are pushed, you can issue `dg build` from the package
directory to create a new package image. The package image includes the list of
component versions, so that running a certain version of the package
deterministically results in component containers of those specific versions.

When the package image is built, it can be pushed as well using `dg push`. Just
like with a component, this will result in a new version of the package in the
registry, and a corresponding tag in the git repo. You can try it out locally
with `dg run {version_number}`.

## Run the package

On a server, use the package image to set up an environment to run the
application. This mechanism hasn't changed; see [On the server](#on-the-server)
for how it works.

## Pipeline

Your Git hosting environment (like GitHub, Azure DevOps, BitBucket, or GitLab)
probably provides a mechanism to automate things when changes are merged. You
could then create a "pipeline" (this is what it's called in Azure DevOps) that
is triggered by a merge in the `main` branch, and performs a _build_ and, when
successful, a _push_. The definition of such a pilepine differs per Git hosting
environment. For Azure DevOps, a basic pipeline is generated on `dg init` and
`dg component`.

Note that the pipeline needs access to the Docker registry; in the generated
pipelines, there's a variable `DOCKER_PASSWORD` that you should provision. Also,
Git permissions are required for the pipeline to commit new version files and
tags. In Azure DevOps, this is configured in Project Settings | Repsitories |
All Repositories | Security; the user `{project name} Build Service ({organsation name})` should get `Allow` for the items "Bypass policies when
pushing", "Contribute", "Create tag", and "Read".

Remember that now the `push` action happens _automatically_, you should refrain
from issuing it "manually" from your development environment.

A companion feature of Azure DevOps is [build
validation](https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops&tabs=browser#build-validation).
To enable this for the a branch, you provide another pipeline definition. Then,
every change to that branch has to come from a pull request; no one can directly
commit to the designated branch anymore. On creation of the pull request (and
any subsequent commit to it), the given pipeline is run, and the pull request
can only be completed (merged) when the pipeline ran successfully.

A basic build validation pipeline, that runs the _build_ action, is generated by
`dg init` and `dg component` as well. This way, you can effectively protect the
`main` branch from ever ending up in a "non-buildable" state.

## Summary

So, in short, what you typically do is:

1. In your new Git repo: `npx --yes docker4gis@latest init` (or `dg init`, if
   you already have the _alias_) to initialise your application's _package_.
1. Create a separate Git repo for each _component_, clone it as a sibling of the
   package repo, and `dg component` to initialise it. The available base
   components are found as repos at
   [https://github.com/merkatorgis/docker4gis-{name}](https://github.com/merkatorgis?tab=repositories).
1. Build each component using `dg build`.
1. Run the application using `dg run`.
   1. As a convenience, to build one component, and run the new image, you can
      use `dg br` ("build & run").
1. Tag a component's version, and push the versioned image to the Docker
   registry, using `dg push`.
1. Once all components are pushed, `dg build` and `dg push` the package as well.
1. On the server:
   1. Run the package image (once) to echo the script that runs the application:
      `docker container run --rm {DOCKER_REGISTRY}/{DOCKER_USER}/package:{tag} > {file_name}`, e.g. `docker container run --rm docker.example.com/theapp/package:237 > theapp`.
   1. Edit the variables in the file to match the environment.
   1. Make the file executable: `chmod +x theapp`.
   1. Execute it: `./theapp 237`.
1. Optionally, configure the repos in your Git hosting environment to use the
   _pipelines_:
   1. Use the _continuous integration_ pipeline to (build and) push
      automatically on each commit to the `main` branch.
   1. Use the _build validation_ pipeline to disallow direct commits to `main`
      and automatically run the build on each _pull request_ before its changes
      can be merged.

## Background: version management

Fitting within a Docker environment, the _images_ of the different components
are considered to be the "unit of change" - when a component is modified, the
resulting changes end up in a new version of the compontent's image, which is
pushed to the Registry, ready to be used in application updates.

### Extending base components

To achieve this goal of providing all changes as "fully contained" images in the
registry, the images of base components include their build and run scripts, as
well as the docker4gis utilities they may depend on.

Specifically, this means:

1. When a base component's image is _built_, the following items are copied into
   the new image:
   1. Its build script (`build.sh`);
   1. Its run script (`run.sh`);
   1. The current docker4gis utilities
      ([/base/.docker4gis/docker4gis](/base/.docker4gis/docker4gis));
1. When a specific application component's image is built (using `dg build`)
   as an _extension_ (`FROM`) a docker4gis base component,
   1. The base component's build script is copied out of its image, and made
      available as `"$BASE"/buid.sh`, as you find referenced in most component
      templates' build scripts.
1. When a new container is _run_ (using `dg run`) from a specific application
   component's image extending a docker4gis base component, the following items
   are copied out of the base component's image:
   1. The base component's run script (`run.sh`);
   1. The docker4gis utilities as they were at the time the base component was
      built, so that they work just as the run script expects; 1. From the run
      script, the utilities are available in the temporary directory
      `docker4gis`.

### Base component versions

When developing a base component itself, any change to its repository's `main`
branch triggers a "pipeline" that builds a new image from the modified code,
increments the version number in the `version` file in the repo, creates a
version tag, and pushes the new image, also tagged with that version number, to
the Docker Hub.

So you can find the precise code that created a base component's image by
selecting the tagged version of the repo that corresponds with the tag of the
image you reference (`FROM`) in your `Dockerfile`.

## Development

Each base docker4gis component resides in its own public repository as a
sibbling of https://github.com/merkatorgis/docker4gis, e.g.
https://github.com/merkatorgis/docker4gis-proxy.

Any GitHub user can fork a component's repo, make changes, confirm things still
build (issuing `dg build`), and create a Pull Request (PR).

When the PR is created (and on any subsequent commits to its originating
branch), a required check has to be run successfully, before the PR enters a
"mergeable" state. This automated check verifies that the component's new code
can still be built.

As a protective measure, the check won't run automatically when the PR comes
from a fork of a user thas isn't a "collaborator" in the base component repo. In
that case, the check is to be triggered by a collaborator through a comment
(`/azp run`) on the PR.

When a PR gets merged, another trigger automatically starts a pipeline that
creates the component's new version, as described
[above](#base-component-versions).

### New base components

Should you aspire to create a whole new base component, then issue `dg
base-component` in a clean repo to scaffold a basic draft.

Everything below this line is "old", and in the process of being rewritten.

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
predictability, which are great enablers for extension and improvement.

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

Create a fork\*) of [the main docker4gis
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
you can update all at once to the most recently pushed version through `./app latest`. That will remove all existing containers, update all images, and then
run everything. To store a newly built, but not yet versioned image of a
specific component, use `./app push {component}` (without any tag).

### On the server

Once your images are in a registry, they're accessible there from your servers.
On a server, the images are never built, only run. So the only thing you need
there, is the little run script that runs the package.

On the server, run:

```
docker container run --rm {DOCKER_REGISTRY}/{DOCKER_USER}/package:{tag} > {DOCKER_USER}
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

Any unit tests are run automatically before building a component with `./app build {component}` - _if any test fails, the build is canceled_.

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

\*) fork & merkatorgis:

- If you fix, extend, or otherwise improve things, please create a pull request,
  so that it can be merged into the originating merkatorgis/docker4gis
  repository.
- When you want to update your fork with new "upstream" changes from
  merkatorgis/docker4gis, use the `compare` function on GitHub:
  https://github.com/${your_account}/docker4gis/compare/master...merkatorgis:master
