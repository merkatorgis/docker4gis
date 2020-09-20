FROM alpine:3.12

RUN apk update; apk add --no-cache \
	ca-certificates wget bash

COPY conf/plugins/bats /tmp/bats
RUN /tmp/bats/install.sh

COPY conf/certificates /tmp/conf/certificates
COPY conf/entrypoint /entrypoint
COPY conf/conf.sh /conf.sh
COPY goproxy/goproxy /goproxy

COPY conf/utils /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh

EXPOSE 80 443

ENTRYPOINT ["/entrypoint"]
CMD ["proxy"]

ONBUILD ADD conf /tmp/conf
ONBUILD RUN cp /tmp/conf/args.sh /.docker4gis

ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER="${DOCKER_USER}"
