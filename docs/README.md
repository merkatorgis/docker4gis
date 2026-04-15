# docker4gis documentation

Docker4gis is an npm package that provides a command-line interface (`dg`) for
managing containerized applications with Docker.

## The general idea

Docker runs applications as containers created from images. Because the image
defines the runtime environment, the same component can behave consistently on
development machines, staging environments, and production servers.

A docker4gis application typically consists of several cooperating components
behind a reverse proxy, for example:

```
                  | - app
                  |
                  | - api
browser - proxy - |    |
                  | - postgis
                  |    |
                  | - geoserver
```

The docker4gis tooling provides base components, templates to extend them, and
the `dg` command to build, run, test, and publish the resulting images.

# Getting started

## Install

In a Bash terminal on a Linux machine (Windows Subsystem for Linux (WSL) is
fine), run:

```
npm install -g docker4gis
```

This will install a command `dg` that you will use to run docker4gis actions.

## Setup new project

From the directory where you want to create your new monorepo, run

```
dg init [PROJECT_NAME] [DOCKER_REGISTRY]
```

If `PROJECT_NAME` is omitted, you'll be asked for it. If `DOCKER_REGISTRY` is
omitted, you'll be asked for it as well.

`dg init` creates the project directory, and a _package_ component is
initialised in `components/^package`.

The package image is used to deterministically run a specific version of the
application, with all the specific versions of the application's different
components.

### Components

The application's "components" are the different containers that comprise the
running application: proxy, app, api, database, geoserver, etc.

To add a component: from somewhere inside the project's directory tree, run

```
dg component [NAME]
```

It will ask you which base docker4gis component it should extend. If the base
component has multiple "flavours", the flavours are listed, and you're asked to
choose one.

Should you need a component that won't act as a "server" that should be started
when the application is run, run `dg standalone` after `dg component`.

The resulting monorepo structure looks like:

```
myapp/                   ← monorepo root
  .env                   ← DOCKER_USER=myapp, DOCKER_REGISTRY=…
  components/
    ^package/            ← package component
      .env               ← DOCKER_REPO=package
      package.json       ← package version
      Dockerfile
      components/        ← list component versions
    proxy/               ← proxy component
      .env
      package.json       ← component version
      Dockerfile
    app/                 ← app component
      …
```

## Build and run

You can build a component's image by issuing `dg build` from its component
directory (or `dg build COMPONENT` from anywhere else in the project).

When all components are built, you can run the application with `dg run`.

When you make a change to a component, and want to see its effect, you can build
the component's image and run the application with the new image in one go,
using `dg br` (for build & run).

There's also `dg b` as short for `dg build`, and `dg r` for `dg run`.

## Push

When you're happy with the changes you made to a component, and you've seen it
running successfully, you should _push_ it by running `dg push [COMPONENT]`.

This will push the new image to the Docker registry (presuming you have logged
in using `docker login`), write a version to the component's `package.json`, tag
the git repo with `{COMPONENT} v-{version_number}`, commit the changes, and push
them to `origin`.

## Build the package

Each time you `dg run` the application, component versions are read from each
component's `package.json`. For components that haven't been pushed yet, a
version `latest` is used.

Once all components are pushed, you can issue `dg build` from the ^package
directory to create a new package image. The package image includes the list of
component versions, so that running a certain version of the package
deterministically results in component containers of those specific versions.

When the package image is built, it can be pushed as well using `dg push`. Just
like with a normal component, this will result in a new version of the package
image in the registry, and a corresponding tag in the git repo. You can try the
new image out locally with `dg run {version_number}`.

## Run the package

On a server, use the package image to set up an environment to run the
application. This mechanism hasn't changed; see [On the server](#on-the-server)
for how it works.

### On the server

Once your images are in a registry, they are accessible from your servers. On a
server, images are typically not built locally; instead, you run the packaged
application version.

Run the package image once to output the startup script:

```
docker container run --rm {DOCKER_REGISTRY}/{DOCKER_USER}/package:{tag} > {DOCKER_USER}
```

For example:

```
docker container run --rm docker.example.com/theapp/package:237 > theapp
```

Then:

1. Edit the variables in the generated file to match the target environment.
1. Make the file executable: `chmod +x theapp`.
1. Run the selected package version: `./theapp 237`.

If your registry requires authentication, log in with Docker first.

## Testing things

Docker4gis supports both component-level tests and application-level tests.

Use `dg test [COMPONENT]` for a specific component's unit tests.

Use `dg test` without a component name to run application-level integration
tests.

During normal development, `dg build` runs a component's tests before building
its image. To build a component and immediately start the application with the
new image, use `dg br [COMPONENT]`.

The detailed testing guide, including the BATS setup and helper conventions, is
available in [testing.md](testing.md).

## Pipeline

Your Git hosting environment (like GitHub, Azure DevOps, BitBucket, or GitLab)
probably provides a mechanism to automate things when changes are merged. You
could then create a "pipeline" (this is what it's called in Azure DevOps) that
is triggered by a merge in the `main` branch, and performs a _build_ and, when
successful, a _push_. The definition of such a pipeline differs per Git hosting
environment. For Azure DevOps, a basic pipeline is generated on `dg init` and
`dg component`.

In the monorepo, each component has its own pipeline YAML files in
`components/<name>/`. Azure DevOps pipeline definitions point to these files.
The pipeline steps use `workingDirectory: components/<name>` so that
docker4gis commands run in the correct component subdirectory.

Note that the pipeline needs access to the Docker registry; in the generated
pipelines, there's a variable `DOCKER_PASSWORD` that you should provision. Also,
Git permissions are required for the pipeline to commit new version files and
tags. In Azure DevOps, this is configured in Project Settings | Repositories |
All Repositories | Security; the user `{project name} Build Service
({organisation name})` should get `Allow` for the items "Bypass policies when
pushing", "Contribute", "Create tag", and "Read".

Remember that now the `push` action happens _automatically_, you should refrain
from issuing it "manually" from your development environment.

A companion feature of Azure DevOps is [build
validation](https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops&tabs=browser#build-validation).
To enable this for a branch, you provide another pipeline definition. Then,
every change to that branch has to come from a pull request; no one can directly
commit to the designated branch anymore. On creation of the pull request (and
any subsequent commit to it), the given pipeline is run, and the pull request
can only be completed (merged) when the pipeline ran successfully.

A basic build validation pipeline, that runs the _build_ action, is generated by
`dg init` and `dg component` as well. This way, you can effectively protect the
`main` branch from ever ending up in a "non-buildable" state.

### Devops

If you use Azure DevOps, you can use `dg devops` to automate Project Setup and
Pipeline Configuration. You'll need a Personal Access Token (PAT) of a DevOps
user that has the right to create new DevOps Projects. See [these
instructions](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?toc=%2Fazure%2Fdevops%2Forganizations%2Ftoc.json&view=azure-devops&tabs=Windows)
on how to create a PAT. You'll need one with the Scope set to `Full Access`.

Just run `dg devops` to get started. Run `dg help devops` for more information.

## Summary

So, in short, what you typically do is:

1. Install docker4gis if you haven't got it yet: `npm install -g docker4gis`.
1. Run `dg init [PROJECT_NAME] [DOCKER_REGISTRY]` to create a new project,
   initialised with its package component.
1. `cd [PROJECT_NAME]`
1. For each _component_: `dg component [NAME]` to initialise it. The available
   base components are found as repos at
   [https://github.com/merkatorgis/docker4gis-{name}](https://github.com/merkatorgis?tab=repositories).
1. Build each component using `dg build [COMPONENT]`, or use `dg all self build` to
   build all components initially.
1. Run the application using `dg run`.
   1. As a convenience, to build one component, and run the new image, you can
      use `dg br [COMPONENT]` ("build & run").
1. Tag a component's version, and push the versioned image to the Docker
   registry, using `dg push [COMPONENT]`.
1. Once all components are pushed, `dg build` and `dg push` the package as well.
1. On the server:
   1. Run the package image (once) to echo the script that runs the application:
      `docker container run --rm {DOCKER_REGISTRY}/{DOCKER_USER}/package:{tag} >
{file_name}`, e.g. `docker container run --rm
docker.example.com/theapp/package:237 > theapp`.
   1. Edit the variables in the file to match the environment.
   1. Make the file executable: `chmod +x theapp`.
   1. Execute it: `./theapp 237`.
1. Optionally, configure the monorepo in your Git hosting environment to use the
   _pipelines_:
   1. Use the _continuous integration_ pipeline (in each `components/<name>/`)
      to push automatically on each commit to the `main` branch.
   1. Use the _build validation_ pipeline to disallow direct commits to `main`
      and automatically run the build on each _pull request_ before its changes
      can be merged.
1. Optionally, if you have Azure DevOps, have all above steps carried out
   automatically, using `dg devops`.

To list all available commands, run `dg` without any arguments.

To read instructions for a specific command, run `dg help COMMAND`.

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
      built, so that they work just as the run script expects; from the run
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

Each base docker4gis component resides in its own public repository as a sibling
of https://github.com/merkatorgis/docker4gis, e.g.
https://github.com/merkatorgis/docker4gis-proxy.

Any GitHub user can fork a component's repo, make changes, confirm things still
build (issuing `dg build`), and create a Pull Request (PR).

When the PR is created (and on any subsequent commits to its originating
branch), a required check has to be run successfully, before the PR enters a
"mergeable" state. This automated check verifies that the component's new code
can still be built.

When a PR gets merged, another trigger automatically starts a pipeline that
creates the component's new version, as described
[above](#base-component-versions).

To try out your local changes to a base component, you can `dg build` it
locally, and then run `dg component local` to create an application component
from it that uses your newly built local base image.

### Local docker4gis development

Use `dgn` for local command development against the current worktree.

- If `dgn` is on `PATH`, run `dgn <command>`.
- Otherwise, run `./dgn <command>` from this repository root.

`dgn` walks up from the current directory and executes the nearest
`docker4gis` script, so it works across parallel worktrees without
global linking.

### New base components

Should you aspire to create a whole new base component, then issue `dg
base-component` in a clean repo to scaffold a basic draft.

Then, when you have something that could work, issue `dg build` to build an
initial local version of the new component's base image. In a new repo of an
existing project, issue `dg template` to set up an environment where you can
test creating an extension of the unpublished new base component. When that
works, copy the scaffold repo's contents (except the `.env` and `package.json`
files) to the `template` directory of the base component.

## Component-specific documentation

For detailed information about specific base components, see their README files:

- [PostGIS](../components/docker4gis-postgis)
- [Proxy](../components/docker4gis-proxy)

Each component's directory contains detailed documentation on configuration,
features, and usage.

