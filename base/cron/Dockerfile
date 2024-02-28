FROM debian:bookworm-20240211

ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER=${DOCKER_USER}

RUN apt update; apt install -y \
	cron rsyslog \
	curl wget unzip

RUN echo '*.* /dev/stdout' > /etc/rsyslog.d/stdout.conf

# Set install time variables for the timezone plugin.
ONBUILD ARG TZ
ONBUILD ENV TZ=${TZ}

# Install timezone plugin.
COPY conf/.plugins/timezone /tmp/timezone
# ONBUILD since we need the TZ variable on install.
ONBUILD RUN /tmp/timezone/install.sh

# Install the runner plugin.
COPY conf/.plugins/runner /tmp/runner
RUN /tmp/runner/install.sh

# Install the cron.sh utility.
COPY conf/cron.sh /usr/local/bin

RUN echo '#!/bin/bash' >/startup.sh; \
	chmod +x /startup.sh

COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["cron"]

# Install the pg plugin.
COPY conf/.plugins/pg /tmp/pg
RUN /tmp/pg/install.sh

# Set run time variables for the pg plugin.
ONBUILD ARG PGHOST
ONBUILD ENV PGHOST=${PGHOST}
ONBUILD ARG PGHOSTADDR
ONBUILD ENV PGHOSTADDR=${PGHOSTADDR}
ONBUILD ARG PGPORT
ONBUILD ENV PGPORT=${PGPORT}
ONBUILD ARG PGDATABASE
ONBUILD ENV PGDATABASE=${PGDATABASE}
ONBUILD ARG PGUSER
ONBUILD ENV PGUSER=${PGUSER}
ONBUILD ARG PGPASSWORD
ONBUILD ENV PGPASSWORD=${PGPASSWORD}

# Make this an extensible docker4gis image.
COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
	cp /tmp/conf/args /.docker4gis
