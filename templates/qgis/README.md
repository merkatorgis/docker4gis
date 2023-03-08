# QGIS Server

Prepare QGIS projects offline on your desktop, and upload them to QGIS Server,
to have the data served as WMS (and more).

## Setup

1. Use this template to create a `qgis` component in your application.
1. Also add a [dynamic](../serve/dynamic) component to serve any
   static files from `$DOCKER_BINDS_DIR/fileport/$DOCKER_USER`.
1. A [proxy](../proxy) component is needed as well, but you probably
   already have it.

## Prepare project in QGIS

1. Create a project in QGIS, and edit the project's properties to define the CRS
   to use. Save the project file.
1. Upload the project file to QGIS Server:
   1. In your browser, go to
      [https://$PROXY_HOST[:$PROXY_PORT][/$DOCKER_USER]/qgisupload/index.php](),
      e.g. [https://localhost:7443/qgisupload/index.php]().
   1. Using the Select Files button, select your QGIS project file (.qgs or
      .qgz).
   1. Now click the Upload button.
   1. When the upload completes, you'll see the project file listed are in a
      newly created directory for your project on the server.
1. Add data layers to the project.
   1. For file based layers (Shapefile, raster, etc.):
      1. Upload the file to the project's directory on QGIS Server first (see
         above).
      1. Then, in the directory listing on the upload page, right-click the data
         file, and copy its URL.
      1. In the QGIS menu, choose Layer | Add Layer | e.g. Add Raster Layer...
         and use the copied URL as the new layer's data source (choose the HTTP
         Protocol Source Type).
      1. If needed (see [below](#qgis-desktop-authentication)), provision the
         Basic authentication credentials for QGIS Server.
1. When done adding layers, zoom to the extent of the widest layer.
1. Edit the project's properties; go to the QGIS Server tab. Under WMS
   capabilities,
   1. Check Advertised extent, and click Use Current Canvas Extent.
   1. Check CRS restrictions, and click Used. Also add EPSG:3857, and EPSG:4326.
1. Edit each layer's properties; go to the QGIS Server tab. Under Description,
   1. Enter a Short name for the layer.
1. Save the project.
1. Upload the project file to QGIS Server again.

## Access project on QGIS Server

Each uploaded project is available as an [OGC WMS
service](https://docs.qgis.org/3.22/en/docs/server_manual/services/wms.html) on
QGIS Server through
[https://$PROXY_HOST[:$PROXY_PORT][/$DOCKER_USER]/qgis/project/$PROJECT_NAME?service=WMS&request=GetCapabilities](),
e.g.
[https://localhost:7443/qgis/project/65521-1?service=WMS&request=GetCapabilities]().

Note that the [MAP
parameter](https://docs.qgis.org/3.22/en/docs/server_manual/services/basics.html#services-basics-map)
should not be given; its set automatically, bases on the `$PROJECT_NAME` part of
the URL.

## Authorisation

The docker4gis proxy automatically provides three paths for QGIS Server:

- `qgis=http://$DOCKER_USER-qgis/qgis/`
- `qgisupload=http://$DOCKER_USER-qgis/upload/`
- `files=http://$DOCKER_USER-dynamic/files/`

And then it works. But. Everything is accessible to everyone. You shouldn't want
that.

### AUTH_PATH

If you haven't already, set a URL value for the
[AUTH_PATH](https://github.com/merkatorgis/docker4gis/blob/master/docs/proxy.md#authorized-destinations)
variable, and serve a handler there, that tests who is logged in, and if the
current request is allowed for that user.

### authorise,

In your proxy component's `conf/args` file, add the following [additional
destinations](https://github.com/merkatorgis/docker4gis/blob/master/docs/proxy.md#additional-destinations):

```
qgis=authorise,http://$DOCKER_USER-qgis/qgis/
qgisupload=authorise,http://$DOCKER_USER-qgis/upload/
files=authorise,http://$DOCKER_USER-dynamic/files/
```

### Check

In your `AUTH_PATH` endpoint, determine who can do what, based on the logged-in
user's roles, a the `path` of the incoming request.

For instance, you could:

- Limit access to paths starting with `/qgis` to users that are logged into your
  application.
- Limit access to paths starting with `/qgisupload` to logged-in users that are
  an administrator.
- For paths starting with `/files`:
  - Deny access for paths that don't start with `/files/qgis`.
  - Limit access to:
    - Logged-in users that are an administrator (for the directory listing in
      the Upload page).
    - Users not logged into the application, but providing correct [Basic
      authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
      credentials (for the map layer sources in QGIS Desktop).

### QGIS Desktop authentication

When authorisation checks are in place, you need a way for QGIS Desktop to
[authenticate](https://docs.qgis.org/3.22/en/docs/user_manual/auth_system/auth_overview.html#authentication-configurations)
itself when acessing the `/files/qgis/...` layer source URLs.

1. In the QGIS menu, choose Settings | Options...
1. Select the Authentication tab.
1. Click the `+` button to add a new authentication configuration.
1. Enter a name, e.g. `QGIS Server`.
1. Ensure that in the drop down item, `Basic authentication` is selected.
1. Enter the Username and Password corresponding with the check that is done in
   the `AUTH_PATH` endpoint.
1. Leave the other fields blank.
1. Click the Save button and close the Options dialog.

Then, when adding a new map layer with a file source, choose the `QGIS Server
(Basic)` authentication configuration from the drop down list.
