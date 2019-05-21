Update this directory with the results of what you configured with the web admin site:

1. Build and run: `./main br geoserver`
1. Start the web admin: `http://localhost:58080/geoserver`
1. Login: `admin/geoserver`
1. Configure things in the web admin.
1. `docker container cp {geoserver_container}:/geoserver/data/workspaces/{app_name} geoserver/conf/{app_name}/workspaces`
1. Build and run again.
