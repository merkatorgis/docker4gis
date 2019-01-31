FROM docker4gis/postgis-gdal

RUN apk update; apk add --no-cache \
		python py2-psycopg2 sudo

ADD conf /tmp/conf

RUN /tmp/conf/ogr_fdw/install.sh
RUN /tmp/conf/odbc_fdw/install.sh
RUN /tmp/conf/tds/install.sh

RUN /tmp/conf/plugins/runner/install.sh
RUN /tmp/conf/plugins/pg/install.sh

RUN	mkdir -p /etc/postgresql /util; \
	mv /tmp/conf/p*.conf /etc/postgresql/; \
	mv /tmp/conf/schema.sh /util/; \
	mv /tmp/conf/entrypoint/* /

ENV PATH=/util:$PATH

ENTRYPOINT ["/entrypoint"]
CMD ["postgis"]

ONBUILD ADD conf /tmp/conf
