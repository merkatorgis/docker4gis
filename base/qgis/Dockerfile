FROM camptocamp/qgis-server:3.22

RUN apt update
RUN apt -y install postgresql-client

COPY conf/.pg_service.conf /
ENV PGSERVICEFILE=/.pg_service.conf
ENV PGSERVICE=qgis

COPY conf/entrypoint /usr/local/bin/entrypoint
ENTRYPOINT [ "entrypoint" ]
CMD [ "qgis" ]

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
    cp /tmp/conf/args /.docker4gis

ONBUILD ARG DOCKER_USER
