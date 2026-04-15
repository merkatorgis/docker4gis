FROM docker4gis/serve:v0.0.15
ENV SINGLE=true

# This may come in handy.
ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER=$DOCKER_USER

# Extension template, as required by `dg component`.
# Replace serve's template with our own.
RUN rm -rf /template
COPY template /template/
# Make this an extensible base component; see
# https://github.com/merkatorgis/docker4gis/tree/npm-package/docs#extending-base-components.

# Keep serve's instances of these:
# COPY conf/.docker4gis /.docker4gis
# COPY run.sh /.docker4gis/run.sh
# But use our own version of this:
COPY build.sh /.docker4gis/build.sh

# Redo these to get them done on the actual build.
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args
ONBUILD RUN cp /tmp/conf/args /.docker4gis

# Add our specific conf files, which may be used by build.sh.
COPY conf/app /.docker4gis/conf/app
