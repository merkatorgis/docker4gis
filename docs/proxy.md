# proxy base image

A reverse proxy, acting as the gateway to the different containers. All your containers are connected through an internal Docker network. Only the proxy container has a port open to the outside. Clients connect to it through the Docker host's standard HTTPS port 443.

HTTP 2.0 is supported.

## Getting started

Copy the `templates/proxy` directory into your project's `Docker` directory. The default `run\build.sh` script will pick things up then.

### Default destinations

The following destinations are baked in, their destinations configured at run time through their corresponding environment variables (sensible defaults are provided):

- /api (API)
- /app (APP)
- /geoserver (GEOSERVER)
- /mapfish (MAPFISH)

### Security

As for now, a proper authentication mechanism is lacking. As a provisional measure, all Geoserver and MapFish requests must supply a `secret` parameter matching the SECRET environment variable. This value is of course readable for users logged into your app, inspecting their browsers' requests. But it does at least deny access to your geodata for passers-by.

This effectively renders the current setup suitable for closed-community applications only.

## Options

### SSL certificate

- Put the `<hostname>.crt` and `<hostname>.key` files in the `conf/certificates` folder.
- In your `run/run.sh` script, set `export PROXY_HOST=<hostname>`

### Additional destinations

In your `run/build.sh` script, extend the line running the proxy, eg:
```
"${here}/scripts/proxy/run.sh" 'extra1=http://container1' 'extra2=https://somewhere.outside.com'
```
So a client request for `https://<hostname>/extra1` will trigger a request from the proxy to `http://container1` and echo the response from there back to the client. Note that containers on the Docker network are addressed by their container name. Also note that since the only route into a container is through the proxy, there's no need for any SSL on the destination containers.

### Home destination
The HOMEDEST environment variable defines the address to redirect to when requesting the root of `https://<hostname>`. It could be set to an external address, or to a local address, eg `/app` for `https://<hostname>/app`.
