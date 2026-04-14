FROM openjdk:8-alpine

RUN apk add maven

VOLUME /root/.m2

VOLUME /src

WORKDIR /src

# Allow configuration before things start up.
COPY conf/entrypoint /entrypoint
ENTRYPOINT ["/entrypoint"]
CMD ["maven"]

# Note that this image is not an extensible base component as in
# https://github.com/merkatorgis/docker4gis/tree/npm-package/docs#extending-base-components.
COPY conf/.docker4gis /.docker4gis
COPY run.sh /.docker4gis/run.sh
RUN touch /.docker4gis/args
