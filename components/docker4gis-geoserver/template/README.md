# Extending docker4gis/geoserver

## Configuration data

After `dg build` and `dg run`, browse to http://localhost:58080 to launch the
GeoServer Administration web page. Log in with `admin`/`geoserver`. This page is
not available through the reverse proxy, locally (on https://localhost:7443) nor
in Production.

1. Create your Workspaces, Data Sources, Layers, Styles, etc. through the
   GeoServer Administration web page.
1. When done, run `dg geoserver` to get the configuration data saved to
   `conf/geoserver_data`.
1. Then `dg build` again, to get the configuration saved in your image.

### Postgis JNDI store

Use `java:comp/env/jdbc/postgres` as the jndiReferenceName. The following
variables can be set in `.env` to override their default values:

- `POSTGRES_HOST=$DOCKER_USER-postgis`
- `POSTGRES_PORT=5432`
- `POSTGRES_DB=postgres`
- `POSTGRES_USERNAME=postgres`
- `POSTGRES_PASSWORD=postgres`

## Additional fonts

Place any font files in `conf/additional_fonts` to have them included.

## Additional libs

Place any plugins/extensions in `conf/additional_libs` to have them included.

## Stable/Community extensions

List any known extensions in the `STABLE_EXTENSIONS` or `COMMUNITY_EXTENSIONS`
environment variables inside `build.sh` to get them downloaded and installed.
See
[https://github.com/geoserver/docker](https://github.com/geoserver/docker#how-to-download-and-install-additional-extensions-on-startup)
for more info. After the build, the extension files will be saved in
`conf/additional_libs`, so that they don't have to be downloaded on any
subsequent build

To list which extensions are already installed in the base component; run:

```
docker container run --rm docker4gis/geoserver ls /opt/additional_libs
```
