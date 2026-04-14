FROM tomcat:9.0.86-jre17-temurin-jammy

ENV PATH=/util:$PATH \
    JAVA_OPTS='-XX:SoftRefLRUPolicyMSPerMB=36000 -XX:NewRatio=2'

# Allow configuration before things start up.
COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["tomcat"]

# Install the bats plugin.
COPY conf/.plugins/bats /tmp/bats
RUN /tmp/bats/install.sh

# Install the runner plugin.
COPY conf/.plugins/runner /tmp/runner
RUN /tmp/runner/install.sh

# Install the pg plugin for the generic PostgreSQL client libraries, as used by
# the JDBC driver.
COPY conf/.plugins/pg /tmp/pg
RUN /tmp/pg/install.sh

COPY conf/CATALINA_HOME /tmp/conf/CATALINA_HOME
COPY conf/webapps /tmp/conf/webapps
COPY conf/subconf.sh /tmp/conf/subconf.sh

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
