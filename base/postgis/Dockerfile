ARG POSTGRESQL_VERSION=13
ARG POSTGIS_VERSION=3.0

# <- postgres:10 <- debian:stretch-slim
FROM postgis/postgis:${POSTGRESQL_VERSION}-${POSTGIS_VERSION}

# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG POSTGRESQL_VERSION
ENV POSTGRESQL_VERSION=${POSTGRESQL_VERSION}

# copy custom postgres configuration files
COPY conf/postgres /etc/postgresql

# update the list of installable packages
RUN apt update

ARG PYTHON=python3
ENV PYTHON=${PYTHON}

# install packages we want throughout
RUN apt install -y \
	apt-transport-https \
	${PYTHON} \
	${PYTHON}-psycopg2

# install packaged postgresql extensions
RUN apt install -y \
	postgresql-${POSTGRESQL_VERSION}-ogr-fdw \
	postgresql-${POSTGRESQL_VERSION}-plsh

ARG MYSQL_VERSION=0.8.16-1
# install mysql repository to
# install package mysql-connector-odbc
ENV MYSQL_VERSION=${MYSQL_VERSION}
# https://dev.mysql.com/get/mysql-apt-config_0.8.16-1_all.deb
COPY conf/src/mysql-apt-config_${MYSQL_VERSION}_all.deb /
RUN apt install -y lsb-release wget; \
	DEBIAN_FRONTEND=noninteractive dpkg -i /mysql-apt-config_${MYSQL_VERSION}_all.deb; \
	apt update; \
	apt install -y mysql-connector-odbc
# install proper paths to the odbc drivers
RUN template=$(mktemp); \
	add() { echo "$1" >> "$template"; }; \
	add '[MySQL ODBC 8.0 Unicode Driver]'; \
	add 'Driver=/usr/lib/x86_64-linux-gnu/odbc/libmyodbc8w.so'; \
	add '[MySQL ODBC 8.0 ANSI Driver]'; \
	add 'Driver=/usr/lib/x86_64-linux-gnu/odbc/libmyodbc8a.so'; \
	odbcinst -i -d -f "$template"

# install packages needed for building several components
ENV BUILD_TOOLS="build-essential"
ENV BUILD_TOOLS="${BUILD_TOOLS} postgresql-server-dev-${POSTGRESQL_VERSION}"
RUN apt install -y ${BUILD_TOOLS}

ARG ODBC_FDW_VERSION=0.5.1
# compile & install odbc_fdw
ENV ODBC_FDW_VERSION=${ODBC_FDW_VERSION}
ENV BUILD_TOOLS="${BUILD_TOOLS} unixodbc-dev"
RUN apt install -y ${BUILD_TOOLS}
# https://github.com/CartoDB/odbc_fdw/archive/0.5.1.tar.gz
ADD conf/src/odbc_fdw-${ODBC_FDW_VERSION}.tar.gz /
RUN cd /odbc_fdw-${ODBC_FDW_VERSION}; \
	make; \
	make install

ARG MONGO_FDW_VERSION=5_2_8
# compile & install mongo_fdw
ENV MONGO_FDW_VERSION=${MONGO_FDW_VERSION}
ENV BUILD_TOOLS="${BUILD_TOOLS} pkg-config"
ENV BUILD_TOOLS="${BUILD_TOOLS} libssl-dev"
ENV BUILD_TOOLS="${BUILD_TOOLS} libsnappy-dev"
ENV BUILD_TOOLS="${BUILD_TOOLS} zlib1g-dev"
ENV BUILD_TOOLS="${BUILD_TOOLS} libzstd-dev"
RUN apt install -y ${BUILD_TOOLS} \
	openssl \
	libsnappy1v5 \
	zlib1g \
	zstd
# https://github.com/EnterpriseDB/mongo_fdw/archive/REL-5_2_8.tar.gz
ADD conf/src/mongo_fdw-REL-${MONGO_FDW_VERSION}.tar.gz /
RUN cd /mongo_fdw-REL-${MONGO_FDW_VERSION}; \
	./autogen.sh --with-master; \
	make; \
	make install

ARG PGJWT_VERSION=0f1aa16
# compile & install pgjwt
ENV PGJWT_VERSION=${PGJWT_VERSION}
# https://github.com/michelp/pgjwt/tarball/master
ADD conf/src/michelp-pgjwt-${PGJWT_VERSION}.tar.gz /
RUN cd /michelp-pgjwt-${PGJWT_VERSION}; \
	make install

ARG PGXN_VERSION=1.3.1
# compile & install PostgreSQL Extension Network client
ENV PGXN_VERSION=${PGXN_VERSION}
# install package python-setuptools,
# which is also needed when running the pgxn client
RUN apt install -y ${PYTHON}-setuptools
# https://github.com/pgxn/pgxnclient/archive/v${PGXN_VERSION}.tar.gz
ADD conf/src/pgxnclient-${PGXN_VERSION}.tar.gz /
# next line currently (2021-03-25) fails with:
#24 2.278   File "/tmp/easy_install-c300t4st/pytest-runner-5.3.0/temp/easy_install-0hocwk0l/setuptools_scm-6.0.1/src/setuptools_scm/__init__.py", line 15, in <module>
#24 2.278   File "/tmp/easy_install-c300t4st/pytest-runner-5.3.0/temp/easy_install-0hocwk0l/setuptools_scm-6.0.1/src/setuptools_scm/version.py", line 42
#24 2.278     trace(f"tag '{tag}' parsed to {result}")
#24 2.278                                           ^
#24 2.278 SyntaxError: invalid syntax
# RUN cd /pgxnclient-${PGXN_VERSION}; \
# 	${PYTHON} setup.py install

# install extension safeupdate from pgxn
# https://github.com/eradman/pg-safeupdate
# http://postgrest.org/en/v7.0.0/admin.html?highlight=safeupdate#block-full-table-operations
# cannot install from pgxn due to failing pgxnclient install (see above)
# RUN pgxn install safeupdate
ARG PGSAFEUPDATE_VERSION=1.3
# compile & install install extension safeupdate
ENV PGSAFEUPDATE_VERSION=${PGSAFEUPDATE_VERSION}
# https://github.com/eradman/pg-safeupdate/archive/refs/tags/${PGSAFEUPDATE_VERSION}.tar.gz
ADD conf/src/pg-safeupdate-${PGSAFEUPDATE_VERSION}.tar.gz /
RUN cd /pg-safeupdate-${PGSAFEUPDATE_VERSION} && \
	make && \
	make install

# install the Microsoft ODBC driver for SQL Server
# https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15
ENV BUILD_TOOLS="${BUILD_TOOLS} curl"
ENV BUILD_TOOLS="${BUILD_TOOLS} apt-transport-https"
ENV BUILD_TOOLS="${BUILD_TOOLS} ca-certificates"
RUN apt install -y ${BUILD_TOOLS}
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
#Download appropriate package for the OS version
# https://www.ionos.com/digitalguide/server/know-how/how-to-check-debian-version/
# https://unix.stackexchange.com/a/316087
RUN curl https://packages.microsoft.com/config/debian/$(cut -d. -f1 /etc/debian_version)/prod.list \
	> /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update; \
	ACCEPT_EULA=Y apt-get install -y msodbcsql17
# optional: for bcp and sqlcmd
RUN ACCEPT_EULA=Y apt-get install -y mssql-tools; \
	echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile; \
	echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc; \
	. ~/.bashrc
# optional: for unixODBC development headers
RUN apt-get install -y unixodbc-dev
# optional: kerberos library for debian-slim distributions
RUN apt-get install -y libgssapi-krb5-2

# remove packages used for building several components
RUN apt remove -y ${BUILD_TOOLS}; \
	apt autoremove -y

# install plugin runner
COPY conf/.plugins/runner/runner.sh /usr/local/bin

# install plugin pg
COPY conf/.plugins/pg/pg.sh /usr/local/bin
COPY conf/.plugins/pg/refresh.sh /usr/local/bin

# install plugin mail
COPY conf/.plugins/mail /tmp/.plugins/mail
RUN /tmp/.plugins/mail/install.sh

# install plugin bats
COPY conf/.plugins/bats /tmp/.plugins/bats
RUN /tmp/.plugins/bats/install.sh

# install tool schema.sh
COPY conf/schema.sh /usr/local/bin

# install source for schema mail
COPY conf/mail /tmp/mail

# install source for schema web
COPY conf/web /tmp/web

# install database server administrative scripts
COPY ["conf/entrypoint", "conf/init.sh", "conf/conf.sh", "conf/onstart.sh", "conf/subconf.sh", "/"]

# install tool last.sh
COPY conf/last.sh /usr/local/bin

# include a "client" image's conf scripts where onstart.sh will find them
ONBUILD COPY conf /tmp/conf

ENTRYPOINT ["/entrypoint"]
CMD ["postgis"]

# have docker4gis contained in this image
COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD RUN touch /tmp/conf/args; \
	cp /tmp/conf/args /.docker4gis
