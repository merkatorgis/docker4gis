FROM debian:bookworm-20231120

ADD conf/src/postgrest-v11.2.1-linux-static-x64.tar.xz /usr/bin

ENV PGUSER="web_authenticator" \
    PGPASSWORD="postgrest" \
    PGRST_DB_PRE_REQUEST="public.pre_request" \
    PGRST_DB_ANON_ROLE="web_anon" \
    PGRST_OPENAPI_SECURITY_ACTIVE="true" \
    PGRST_SERVER_PORT="8080"

ENV PGRST_DB_EXTRA_SEARCH_PATH=public \
    PGRST_DB_MAX_ROWS= \
    PGRST_DB_POOL=100 \
    PGRST_DB_ROOT_SPEC= \
    PGRST_JWT_AUD= \
    PGRST_JWT_ROLE_CLAIM_KEY=".role" \
    PGRST_JWT_SECRET_IS_BASE64=false \
    PGRST_RAW_MEDIA_TYPES= \
    PGRST_SERVER_HOST=*4

# Allow configuration before things start up.
COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["postgrest"]

# Example plugin use.
# COPY conf/.plugins/bats /tmp/bats
# RUN /tmp/bats/install.sh

# This may come in handy.
ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER=$DOCKER_USER

ONBUILD ARG PGDATABASE
ONBUILD ENV PGDATABASE=${PGDATABASE:-postgres}

ONBUILD ENV PGHOST=$DOCKER_USER-postgis
ONBUILD ENV PGRST_DB_SCHEMAS=$DOCKER_USER

# Extension template, as required by `dg component`.
COPY template /template/
# Make this an extensible base component; see
# https://github.com/merkatorgis/docker4gis/tree/npm-package/docs#extending-base-components.
COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args
ONBUILD RUN cp /tmp/conf/args /.docker4gis
