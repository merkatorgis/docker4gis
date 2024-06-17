# https://code.visualstudio.com/docs/containers/quickstart-aspnet-core

# Learn about building .NET container images:
# https://hub.docker.com/_/microsoft-dotnet-aspnet/
# https://github.com/dotnet/dotnet-docker/blob/main/samples/aspnetapp/Dockerfile.chiseled-composite

# 8.0.3-jammy-chiseled-composite
FROM mcr.microsoft.com/dotnet/nightly/aspnet:8.0.3-jammy

ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER=${DOCKER_USER}

# Set run time variables for the PostgreSQL connection.

ONBUILD ARG PGHOST
ONBUILD ENV PGHOST=${PGHOST:-$DOCKER_USER-postgis}

ONBUILD ARG PGHOSTADDR
ONBUILD ENV PGHOSTADDR=${PGHOSTADDR:-$PGHOST}

ONBUILD ARG PGPORT
ONBUILD ENV PGPORT=${PGPORT:-5432}

ONBUILD ARG PGDATABASE
ONBUILD ENV PGDATABASE=${PGDATABASE:-postgres}


EXPOSE 8080
WORKDIR /app

COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["aspdotnet"]

# Make this an extensible docker4gis image.
COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
    cp /tmp/conf/args /.docker4gis
