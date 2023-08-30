FROM alpine:3.12

RUN apk update; apk add --no-cache \
    bash

COPY conf/.docker4gis /.docker4gis

COPY setup.sh /setup.sh
COPY run.sh /run.sh

CMD [ "/setup.sh" ]

ONBUILD COPY conf/run.sh /.docker4gis/run.sh

ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER=$DOCKER_USER

ONBUILD ARG DOCKER_REGISTRY
ONBUILD ENV DOCKER_REGISTRY=$DOCKER_REGISTRY
