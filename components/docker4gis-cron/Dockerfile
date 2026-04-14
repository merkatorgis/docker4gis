FROM alpine:3.20.3

RUN apk update; apk add --no-cache \
    bash curl wget unzip grep sed

# Create the file that /entrypoint will run at container startup. To create
# startup jobs, use `cron.sh startup SCRIPT [PARAMETER...]`, or `cron.sh
# SCHEDULE SCRIPT startup [PARAMETER...]`; see conf/cron.sh. 
RUN startup=/startup.sh; \
    echo '#!/bin/bash' >"$startup"; \
    echo 'set -x' >>"$startup"; \
    chmod +x "$startup"

# Allow configuration before things start up.
COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["cron"]

# Install the cron.sh utility.
COPY conf/cron.sh /usr/local/bin/

# Install the bats plugin.
COPY conf/.plugins/bats /tmp/bats
RUN /tmp/bats/install.sh

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

# Install the mail plugin.
COPY conf/.plugins/mail /tmp/mail
RUN /tmp/mail/install.sh

# This may come in handy.
ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER=$DOCKER_USER

# Extension template, as required by `dg component`.
COPY template /template/
# Make this an extensible base component; see
# https://github.com/merkatorgis/docker4gis/tree/npm-package/docs#extending-base-components.
COPY conf/.docker4gis /.docker4gis
COPY build.sh run.sh /.docker4gis/
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args
ONBUILD RUN cp /tmp/conf/args /.docker4gis/
