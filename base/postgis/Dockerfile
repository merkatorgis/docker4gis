ARG POSTGRESQL_VERSION
ARG POSTGIS_VERSION

# postgis/postgis:10-2.5 <- debian:stretch = 9
# postgis/postgis:10-3.2 <- debian:bullseye = 11
# postgis/postgis:11-2.5 <- debian:stretch = 9
# postgis/postgis:11-3.2 <- debian:bullseye = 11
# postgis/postgis:12-3.2 <- debian:bullseye = 11
# postgis/postgis:13-3.2 <- debian:bullseye = 11
# postgis/postgis:14-3.2 <- debian:bullseye = 11
# postgis/postgis:16-3.4 <- debian:bullseye = 11
FROM postgis/postgis:${POSTGRESQL_VERSION}-${POSTGIS_VERSION}

# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG POSTGRESQL_VERSION
ENV POSTGRESQL_VERSION=${POSTGRESQL_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

# update the list of installable packages
RUN apt update

ARG PYTHON
ENV PYTHON=${PYTHON}

# install packages we want throughout
RUN apt install -y \
	apt-transport-https \
	${PYTHON} \
	${PYTHON}-psycopg2

# install packaged postgresql extensions
RUN apt install -y \
	postgresql-${POSTGRESQL_VERSION}-ogr-fdw \
	postgresql-${POSTGRESQL_VERSION}-plsh \
	postgresql-${POSTGRESQL_VERSION}-pldebugger

# install packages needed for building several components
ENV BUILD_TOOLS="build-essential"
ENV BUILD_TOOLS="${BUILD_TOOLS} postgresql-server-dev-${POSTGRESQL_VERSION}"
RUN apt install -y ${BUILD_TOOLS}

ARG MONGO_FDW_VERSION
# compile & install mongo_fdw
ENV MONGO_FDW_VERSION=${MONGO_FDW_VERSION}
ENV BUILD_TOOLS="${BUILD_TOOLS} cmake"
ENV BUILD_TOOLS="${BUILD_TOOLS} pkg-config"
ENV BUILD_TOOLS="${BUILD_TOOLS} libssl-dev"
ENV BUILD_TOOLS="${BUILD_TOOLS} libsnappy-dev"
ENV BUILD_TOOLS="${BUILD_TOOLS} zlib1g-dev"
ENV BUILD_TOOLS="${BUILD_TOOLS} libzstd-dev"
ENV BUILD_TOOLS="${BUILD_TOOLS} clang-13"
RUN apt install -y ${BUILD_TOOLS} \
	wget \
	openssl \
	libsnappy1v5 \
	zlib1g \
	zstd
# https://github.com/EnterpriseDB/mongo_fdw/archive/REL-5_2_8.tar.gz
ADD conf/src/mongo_fdw-REL-${MONGO_FDW_VERSION}.tar.gz /
RUN cd /mongo_fdw-REL-${MONGO_FDW_VERSION}; \
	./autogen.sh --with-master; \
	export PKG_CONFIG_PATH="$PKG_CONFIG_PATH":/lib/pkgconfig/; \
	make; \
	make install

ARG PGJWT_VERSION
# compile & install pgjwt
ENV PGJWT_VERSION=${PGJWT_VERSION}
# https://github.com/michelp/pgjwt/tarball/master
ADD conf/src/michelp-pgjwt-${PGJWT_VERSION}.tar.gz /
RUN cd /michelp-pgjwt-${PGJWT_VERSION}; \
	make install

ARG PGXN_VERSION
# compile & install PostgreSQL Extension Network client
ENV PGXN_VERSION=${PGXN_VERSION}
# install package python-pip, and python-setuptools,
# which is also needed when running the pgxn client
RUN apt install -y ${PYTHON}-setuptools ${PYTHON}-pip
RUN pip3 install pytest-runner || true
# https://github.com/pgxn/pgxnclient/archive/v${PGXN_VERSION}.tar.gz
ADD conf/src/pgxnclient-${PGXN_VERSION}.tar.gz /
RUN cd /pgxnclient-${PGXN_VERSION}; \
	${PYTHON} setup.py install

# install extension safeupdate from pgxn
# https://github.com/eradman/pg-safeupdate
# http://postgrest.org/en/v7.0.0/admin.html?highlight=safeupdate#block-full-table-operations
RUN pgxn install safeupdate
# # compile & install install extension safeupdate (when pgxn doesn't work)
# ARG PGSAFEUPDATE_VERSION
# ENV PGSAFEUPDATE_VERSION=${PGSAFEUPDATE_VERSION}
# # https://github.com/eradman/pg-safeupdate/archive/refs/tags/${PGSAFEUPDATE_VERSION}.tar.gz
# ADD conf/src/pg-safeupdate-${PGSAFEUPDATE_VERSION}.tar.gz /
# RUN cd /pg-safeupdate-${PGSAFEUPDATE_VERSION} && \
# 	make && \
# 	make install

# for postgresql < 14, install range_agg as an extension from pgxn
# https://pgxn.org/dist/range_agg/
RUN [ "$POSTGRESQL_VERSION" -lt 14 ] && pgxn install range_agg || true

# install the Microsoft ODBC driver for SQL Server
# https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15
ENV BUILD_TOOLS="${BUILD_TOOLS} curl"
ENV BUILD_TOOLS="${BUILD_TOOLS} apt-transport-https"
ENV BUILD_TOOLS="${BUILD_TOOLS} ca-certificates"
ENV BUILD_TOOLS="${BUILD_TOOLS} unixodbc-dev"
RUN apt install -y ${BUILD_TOOLS}
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
#Download appropriate package for the OS version
# https://www.ionos.com/digitalguide/server/know-how/how-to-check-debian-version/
# https://unix.stackexchange.com/a/316087
RUN curl https://packages.microsoft.com/config/debian/$(cut -d. -f1 /etc/debian_version)/prod.list \
	> /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update; \
	ACCEPT_EULA=Y apt-get install -y msodbcsql18 || \
	ACCEPT_EULA=Y apt-get install -y msodbcsql17
# optional: for bcp and sqlcmd
RUN ACCEPT_EULA=Y apt-get install -y mssql-tools; \
	echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile; \
	echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc; \
	. ~/.bashrc
# prevent TCP Provider: Error code 0x2746
# https://stackoverflow.com/a/59503719
# https://github.com/microsoft/msphpsql/issues/1021
RUN sed -i 's/CipherString = DEFAULT@SECLEVEL=2/CipherString = DEFAULT@SECLEVEL=1/g' /etc/ssl/openssl.cnf

# remove packages used for building several components
RUN apt remove -y ${BUILD_TOOLS}; \
	apt autoremove -y

# Install the mysql client.
RUN apt install -y default-mysql-client

# Prevent "ERROR:  UPDATE requires a WHERE clause" when running
# update-postgis.sh.
RUN script=$(which update-postgis.sh) && \
	sed -i 's/psql/psql -1 -c "SET safeupdate.enabled=0"/' "$script"

# Install the runner plugin.
COPY conf/.plugins/runner /tmp/runner
RUN /tmp/runner/install.sh

# install plugin mail
COPY conf/.plugins/mail /tmp/.plugins/mail
RUN /tmp/.plugins/mail/install.sh

# Install the pg plugin (without "re-installing" the postgresql-client package).
COPY conf/.plugins/pg /tmp/pg
RUN /tmp/pg/install.sh no_client

# Set run time variables for the pg plugin.
ONBUILD ARG PGHOST
ONBUILD ENV PGHOST=${PGHOST}
ONBUILD ARG PGHOSTADDR
ONBUILD ENV PGHOSTADDR=${PGHOSTADDR}
ONBUILD ARG PGPORT
ONBUILD ENV PGPORT=${PGPORT:-5432}
ONBUILD ARG PGDATABASE
ONBUILD ENV PGDATABASE=${PGDATABASE:-postgres}
ONBUILD ARG PGUSER
ONBUILD ENV PGUSER=${PGUSER:-postgres}
ONBUILD ARG PGPASSWORD
ONBUILD ENV PGPASSWORD=${PGPASSWORD:-postgres}

# See https://hub.docker.com/_/postgres.
ONBUILD ENV POSTGRES_PASSWORD=${PGPASSWORD}
ONBUILD ENV POSTGRES_USER=${PGUSER}
ONBUILD ENV POSTGRES_DB=${PGDATABASE}

# install plugin bats
COPY conf/.plugins/bats /tmp/.plugins/bats
RUN /tmp/.plugins/bats/install.sh

# install tool schema.sh
COPY conf/schema.sh /usr/local/bin

# install source for schema mail
COPY conf/mail /tmp/mail

# install source for schema web
COPY conf/web /tmp/web

# install source for schema admin
COPY conf/admin /tmp/admin

# install database server administrative scripts
COPY ["conf/entrypoint", "conf/conf.sh", "conf/onstart.sh", "conf/subconf.sh", "/"]

# install tools

COPY conf/last.sh /usr/local/bin/

COPY conf/dump_restore /usr/local/bin/dump
COPY conf/dump_restore /usr/local/bin/restore
COPY conf/dump_restore /usr/local/bin/upgrade
COPY conf/dump_restore /usr/local/bin/dump_schema
COPY conf/dump_restore /usr/local/bin/restore_schema

COPY conf/ogr_dummy.json /tmp/conf/
RUN chown postgres:postgres /tmp/conf/ogr_dummy.json
COPY conf/fdw /usr/local/bin/

# copy custom postgres configuration files
COPY conf/postgres /etc/postgresql
ENV CONFIG_FILE=/etc/postgresql/postgresql.conf
RUN mv "${CONFIG_FILE}" "${CONFIG_FILE}.template"
RUN [ "$POSTGRESQL_VERSION" -le 11 ] \
	&& echo 'hostssl all             all             all                     md5       clientcert=1' >> /etc/postgresql/pg_hba.conf \
	|| echo 'hostssl all             all             all                     cert' >> /etc/postgresql/pg_hba.conf

ENTRYPOINT ["/entrypoint"]
CMD ["postgis"]

# have docker4gis contained in this image
COPY conf/.docker4gis /.docker4gis
COPY build.sh run.sh /.docker4gis/
ONBUILD COPY conf/args /.docker4gis/

ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER=${DOCKER_USER}
