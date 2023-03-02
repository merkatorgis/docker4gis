FROM camptocamp/qgis-server:3.22

# Install php.
RUN apt update
RUN apt install -y php libapache2-mod-php

# Higher file upload limit.
RUN echo upload_max_filesize = 500M >>/etc/php/7.4/apache2/php.ini
RUN echo post_max_size = 510M >>/etc/php/7.4/apache2/php.ini

# Our php app, reachable via
# https://<PROXY_HOST>/<DOCKER_USER>/qgisupload/index.php, or
# https://localhost:7443/<DOCKER_USER>/qgisupload/index.php.
COPY conf/upload /var/www/html/upload

# Run the qgis-mapserv-wrapper script for urls starting with /qgis/, instead of
# for _all_ urls, so that we can run php scripts as well.
RUN sed -i 's~"\^/\.\*"~"^/qgis/.*"~g' /etc/apache2/conf-enabled/qgis.conf

# Add custom configuration to qgis.conf's <LocationMatch> directive.
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
