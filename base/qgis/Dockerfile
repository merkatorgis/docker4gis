FROM camptocamp/qgis-server:3.22

# Install php.
RUN apt update
RUN apt install -y php libapache2-mod-php
COPY conf/info.php /var/www/html/

# Run the qgis-mapserv-wrapper script for urls starting with /qgis/, instead of
# for _all_ urls, so that we can run php scripts as well.
RUN sed -i 's~"\^/\.\*"~"^/qgis/.*"~g' /etc/apache2/conf-enabled/qgis.conf

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args
ONBUILD RUN cp /tmp/conf/args /.docker4gis
