FROM docker4gis/postgis-gdal:11-3.0.1

RUN apk update; apk add --no-cache \
		python py2-psycopg2 sudo

ENV OGR_FDW_VERSION 1.0.8
COPY conf/ogr_fdw /tmp/ogr_fdw
RUN /tmp/ogr_fdw/install.sh

COPY conf/odbc_fdw /tmp/odbc_fdw
RUN /tmp/odbc_fdw/install.sh

COPY conf/tds /tmp/tds
RUN /tmp/tds/install.sh

COPY conf/plsh /tmp/plsh
RUN /tmp/plsh/install.sh

COPY conf/pgjwt /tmp/pgjwt
RUN /tmp/pgjwt/install.sh

COPY conf/plugins/runner /tmp/plugins/runner
RUN /tmp/plugins/runner/install.sh

COPY conf/plugins/pg /tmp/plugins/pg
RUN /tmp/plugins/pg/install.sh

ENV PATH=/util:$PATH

COPY conf/util /util
COPY conf/postgres /etc/postgresql
COPY conf/conf.sh /tmp/conf/conf.sh
COPY conf/auth /tmp/conf/auth

COPY conf/entrypoint /entrypoint
ENTRYPOINT ["/entrypoint"]
CMD ["postgis"]

ONBUILD ADD conf /tmp/conf
