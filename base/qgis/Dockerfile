FROM camptocamp/qgis-server:3.22

COPY conf/include.conf /tmp/include.conf
RUN sed -i 's~\(</LocationMatch>\)~    Include /tmp/include.conf\n\1~g' /etc/apache2/conf-enabled/qgis.conf

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args
ONBUILD RUN cp /tmp/conf/args /.docker4gis

ONBUILD ARG DOCKER_USER
