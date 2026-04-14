# check=skip=InvalidDefaultArgInFrom

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install the bats plugin.
COPY conf/.plugins/bats /tmp/bats
RUN /tmp/bats/install.sh

# Install the runner plugin.
COPY conf/.plugins/runner /tmp/runner
RUN /tmp/runner/install.sh

# Install the pg plugin.
COPY conf/.plugins/pg /tmp/pg
RUN /tmp/pg/install.sh

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

COPY conf/schema.sh /usr/local/bin/
COPY conf/last.sh /usr/local/bin/
COPY ["conf/subconf.sh", "conf/onstart.sh", "/"]

COPY conf/mail /tmp/mail
COPY conf/web /tmp/web
COPY conf/admin /tmp/admin
COPY conf/wms /tmp/wms

# Allow configuration before things start up.
COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["postgis-ddl"]

# Make this image work with dg build & dg push.
COPY conf/.docker4gis /.docker4gis
COPY build.sh run.sh /.docker4gis/

# Set environment variables.
ONBUILD ARG DOCKER_REGISTRY
ONBUILD ENV DOCKER_REGISTRY=$DOCKER_REGISTRY
ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER=$DOCKER_USER
ONBUILD ARG DOCKER_REPO
ONBUILD ENV DOCKER_REPO=$DOCKER_REPO

# Make this an extensible base component; see
# https://github.com/merkatorgis/docker4gis/tree/npm-package/docs#extending-base-components.
COPY template /template/

