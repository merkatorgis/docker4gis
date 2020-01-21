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

As for now, a proper authentication mechanism is lacking.
As a provisional measure, all Geoserver, MapServer, MapProxy, and MapFish requests
must supply a `secret` parameter matching the `${SECRET}` environment variable, if that is set.
This value is of course readable for users logged into your app, inspecting their browsers' requests.
But it does at least deny access to your geodata for passers-by.

For public data services, you can leave the request parameter out, and leave the environment variable unset.

### Multiple applications

Different applications (collections of docker4gis containers sharing the ${DOCKER_USER} value),
running on a single Docker host, share the same single `docker4gis-proxy` container.
Starting point for each application's routes is `https://${PROXY_HOST}/${DOCKER_USER}`.

(However, if the starting `${DOCKER_USER}` path component is missing,
the route will be handled as if it belonged to the `${DOCKER_USER}` of
the image that the `docker4gis-proxy` container is running from)

## Options

### SSL certificate

- Put the `${PROXY_HOST}.crt` and `${PROXY_HOST}.key` files in the `conf/certificates` folder.
- Configure the `PROXY_HOST=${PROXY_HOST}` variable

### Additional destinations

In your `run/build.sh` script, extend the line running the proxy, eg:
```
component proxy     "${DOCKER_BASE}/proxy" \
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

