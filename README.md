[![Merkator logo](logo.png)](https://www.merkator.com/)

# docker4gis

Quickly pull up a stable baseline for your Geographical Information System, by extending some of the Docker images for common GIS components:

- PostGIS database, including authenticated PostgREST API option w/ Swagger UI
- MySQL database
- GeoServer and MapServer for map services
- MapProxy for caching or transfroming map services
- MapFish for printing maps in PDF templates
- Postfix mailserver
- Cron for scheduled tasks
- Elm Single Page App server
- Tomcat or Glassfish Java API server
- HTTP static file server
- Reverse Proxy
- Docker registry

Enjoy having exactly the same setup on each server __and__ develepment environment.

Set up a new environment by copying a 10-line script, setting 5 environment variables, and issuing a 1-word command.

Migrate each environment to the next release by issuing the same 1-word command, adding the version number.

## Community-strengthened

The more projects using Docker4GIS, the more issues are reported, the more bugs are fixed, the more features are proposed, the more pull requests are merged.
Join in, use everything for free, communicate, and help to grow it bigger, and stronger.

## Docker Hub

Base images are available on [Docker Hub](https://hub.docker.com/u/docker4gis). The scripts to build these are in this repo.

## Getting started

- We're creating an Example project to show how to typically set things up.
- We're adding [documentation](docs) explaining all the special features as well.
- To quickly pull up a development environment, follow our [Cloud Dev Env Guide](docs/clouddevenv.md). Or, [check](docs#development-environment) what you'd need on your laptop.

## Enquiries

Please use this repo's Issue board.
