FROM docker4gis/serve:v0.0.15

ENV DYNAMIC=true

# This may come in handy.
ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER=$DOCKER_USER

# Extension template, as required by `dg component`. Replace the
# docker4gis-serve version.
RUN rm -rf /template/
COPY template /template/
# Make this an extensible base component; see
# https://github.com/merkatorgis/docker4gis/tree/npm-package/docs#extending-base-components.
# Use the docker4gis-serve versions of these two.
# COPY conf/.docker4gis /.docker4gis
# COPY build.sh run.sh /.docker4gis/
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args
ONBUILD RUN cp /tmp/conf/args /.docker4gis/
