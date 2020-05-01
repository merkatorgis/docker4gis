# proxy base image

A reverse proxy, acting as the gateway to the different containers.
All your containers are connected through an internal Docker network.
Only the proxy container has a port open to the outside.
Clients connect to it through the Docker host's standard HTTPS port 443
(HTTP on port 80 redirects request to the HTTPS port).

HTTP 2.0 is supported.

## Getting started

Copy the [`templates/proxy`](/templates/proxy) directory into your project's `docker` directory.
The default `.package\build.sh` script will pick things up then.

### Default destinations

The following destinations are baked in:

- /${DOCKER_USER}/geoserver
- /${DOCKER_USER}/mapserver
- /${DOCKER_USER}/mapproxy
- /${DOCKER_USER}/mapfish
- /${DOCKER_USER}/swagger
- /${DOCKER_USER}/resources

And for the following two, their destinations are configured at run time
through their corresponding environment variables (sensible defaults are provided):

- /${DOCKER_USER}/api (API)
- /${DOCKER_USER}/app (APP)

### Security

#### PostgREST
If you add the [`postgis`](/templates/postgis) and [`postgrest`](/templates/postgrest)
components, you get a user database (verified email address & secured password)
and a fully [JWT](https://jwt.io/) authenticated automatic HTTP/JSON API
to the database - see [PostgREST](http://postgrest.org).
Add the [`swagger`](/templates/swagger) component as well for easy API browsing.

#### String identifiers
For the Geoserver, MapServer, MapProxy, and MapFish components, if the
`${SECRET}` environment variable is set, requests must supply a `secret`
URL parameter matching its value.

A better generic option for those components is to include a customer/tenant/user-specific
`access_token` string that is copied into every query the component issues to
the database.
In GeoServer, you can use a `view_param` in a [`sql_view`](https://docs.geoserver.org/stable/en/user/data/database/sqlview.html#parameterizing-sql-views)
definition.
In MapServer, you can use [runtime subtitution](https://mapserver.org/cgi/runsub.html)
of URL parameters.

#### Authorized destinations
Any proxy destination can be marked to `authorise`. In that case,
access for each request is first tested by issuing a `GET` request to the
URL in the `AUTH_PATH` environment variable, with a `method`
(GET/PUT/POST/DELETE) and a `path` parameter (any request headers come along
as well): it should return either status `200 OK` or `401 Unautorized`.

### Multiple applications

Different applications (collections of docker4gis containers sharing the ${DOCKER_USER} value),
running on a single Docker host, share the same single `docker4gis-proxy` container.
Starting point for each application's routes is `https://${PROXY_HOST}/${DOCKER_USER}`.

(However, if the starting `${DOCKER_USER}` path component is missing,
the route will be handled as if it belonged to the `${DOCKER_USER}` of
the image that the `docker4gis-proxy` container is running from)

## Options

### SSL certificate

- If the `PROXY_HOST` environment variable starts with `localhost`,
or `DOCKER_ENV` is `DEVELOPMENT`,
or `AUTOCERT` is not `true`,
then there shoud be a `{PROXY_HOST}.crt` and a `{PROXY_HOST}.key` file
in `{DOCKER_BINDS_DIR}/certificates` (a self-signed `localhost.crt` and
`localhost.key` pair is provided)
- Otherwise (on a server with a proper domain name), a
[Let's Encrypt](https://letsencrypt.org/) certificate is generated and
installed automatically - it will also be automatically renewed 30 days
before expiration.

### Additional destinations

In your `run/build.sh` script, extend the line running the proxy, eg:
```
component proxy     "${DOCKER_BASE}/proxy" \
	dynamic="authorise,http://${DOCKER_USER}-dynamic" \
	extra1=http://container1 \
	extra2=https://somewhere.outside.com
```
So a client request for `https://${PROXY_HOST}/${DOCKER_USER}/extra1` will trigger a request
from the proxy to `http://container1` and echo the response from there back to the client.
Note that containers on the Docker network are addressed by their container name.
Also note that since the only route into a container is through the proxy,
there's no need for any SSL on the destination containers.

### Home destination

The `${HOMEDEST}` environment variable, defines the address to redirect to
when requesting the root of `https://${PROXY_HOST}/${DOCKER_USER}`.
Its default value is set to the `/${DOCKER_USER}/app` path on the proxy server.

