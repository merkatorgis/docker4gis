Update this directory with the results of what you configured with the web admin site.

1. After first run, notice the port number: `0.0.0.0:_32769_->8080/tcp`
1. Start the web admin: `http://localhost:{port}/geoserver`
1. Login: `admin/geoserver`
1. Configure things in the web admin.
1. `docker container exec {geoserver-container} bash -c 'cp -r ${GEOSERVER_DATA_DIR}/workspaces /fileport'`
1. Copy the specific workspace contents from `${DOCKER_BASE}../binds/fileport/workspaces` to this very directory here.
