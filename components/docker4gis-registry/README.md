# docker4gis-registry

Runs a self-hosted Docker Registry on your server.

This is not a base component that you extend from. It's a standalone component
that you can run on a server, by copying the `run.sh` script to there, and
editing the environment variables at the top of the file.

## User accounts

Copy the `adduser.sh` script as well to create registry users on your server.

Users with names starting with `merkator/` have access to all images paths. Other ("project") users only have access to images named `${user}/*`.

Use `merkator/` users only for personal developer accounts. Create a normal
"project" user for each docker4gis application/project, so that they can push
and pull all of their own components' images, and none that belong to other
projects. Only use project accounts on application servers; never login as a
`merkator/` user on an application server.

## Configuration

In the `run.sh` copy on your server, set the environment variables:
- `tag`: the version of the `docker4gis/registry` proxy to run.
- `REGISTRY_HOST`: a fully qualified domain name (register it in DNS).
- `AUTOCERT`: `true`, so that a trusted certificate is requested from
  LetsEncrypt.
- `DOCKER_ENV`: `PRODUCTION`.
