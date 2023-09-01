FROM camptocamp/qgis-server:3.32.0

# https://stackoverflow.com/a/65054734/2389922
ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install php.
RUN apt update
RUN apt install -y php libapache2-mod-php

# Higher file upload limit.
RUN echo upload_max_filesize = 500M >>/etc/php/*/apache2/php.ini
RUN echo post_max_size = 510M >>/etc/php/*/apache2/php.ini

# Our php app, reachable via
# https://<PROXY_HOST>/<DOCKER_USER>/qgisupload/index.php, or
# https://localhost:7443/<DOCKER_USER>/qgisupload/index.php.
COPY conf/upload /var/www/html/upload

# In qgis.conf, for both the ScriptAliasMatch and the <LocationMatch>, replace
# the default "^/.*" with "^/qgis/.*", so that the qgis-mapserv-wrapper script
# is run for all URLs starting with /qgis/, instead of for _all_ URLs. This
# allows us to run php scripts for non-/qgis/* paths.
RUN sed -i 's~"\^/\.\*"~"^/qgis/.*"~g' /etc/apache2/conf-enabled/qgis.conf

# Add custom configuration to qgis.conf's <LocationMatch "^/qgis/.*"> directive.
COPY conf/include.conf /tmp/include.conf
RUN sed -i 's~\(</LocationMatch>\)~    Include /tmp/include.conf\n\1~g' /etc/apache2/conf-enabled/qgis.conf

COPY conf/entrypoint /usr/local/bin
ENTRYPOINT [ "entrypoint" ]
CMD [ "qgis" ]

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args
ONBUILD RUN cp /tmp/conf/args /.docker4gis
