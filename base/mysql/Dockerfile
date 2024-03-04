FROM mysql:8.0.17

COPY conf/.plugins/mysql /tmp/mysql
ONBUILD RUN /tmp/mysql/install.sh

# Set run time variables for the mysql plugin.
ONBUILD ARG MYSQL_DATABASE
ONBUILD ENV MYSQL_DATABASE=${MYSQL_DATABASE:-mysql}
ONBUILD ARG MYSQL_ROOT_PASSWORD
ONBUILD ENV MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-mysql}

COPY conf/.plugins/bats /tmp/bats
RUN /tmp/bats/install.sh

COPY conf/entrypoint /entrypoint
COPY conf/conf.sh /tmp/conf.sh
COPY conf/subconf.sh /tmp/subconf.sh

COPY conf/schema.sh /usr/local/bin/schema.sh

ENTRYPOINT ["/entrypoint"]
CMD ["mysqld"]

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
	cp /tmp/conf/args /.docker4gis
