[![Merkator logo](logo.png)](https://www.merkator.com/)

# docker4gis

Quickly pull up a stable baseline for your Geographical Information System, by
extending some of the Docker images for common GIS components:

- Reverse proxy
- PostGIS database
- PostgREST API server
- GeoServer for map services
- Angular frontend
- ASP.NET application
- Maven build environment
- Tomcat Java application server
- Cron for scheduled tasks
- Postfix mailserver
- Swagger UI
- HTTP static file server
- More will follow...

There's a Docker Registry component to self-host as well.

## What you ship is what you get

Enjoy having exactly the same setup on each server __and__ develepment
environment.

Set up a new environment by copying a 10-line script, setting 5 environment
variables, and issuing a 1-word command.

Migrate each environment to the next release by issuing the same 1-word command,
adding the version number.

Or use the included Azure DevOps pipelines to deploy automatically.

## Docker Hub

Base images are available on [Docker Hub](https://hub.docker.com/u/docker4gis).
The scripts to build these are in this repo.

## Getting started

- Full [documentation](docs) explaining how to use docker4gis, set up projects,
  and manage components.
- Component-specific documentation is available in each component's directory.
- To quickly pull up a development environment, see the [documentation](docs)
  for requirements and setup instructions.

## Enquiries

Please use this repo's Issue board.
