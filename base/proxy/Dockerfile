FROM alpine:3.12

RUN apk update; apk add --no-cache \
	ca-certificates wget bash

COPY conf/plugins/bats /tmp/bats
RUN /tmp/bats/install.sh

COPY conf/certificates /tmp/conf/certificates
COPY conf/entrypoint /entrypoint
COPY conf/conf.sh /conf.sh
COPY goproxy/goproxy /goproxy

EXPOSE 80 443

ENTRYPOINT ["/entrypoint"]
CMD ["proxy"]

ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER="${DOCKER_USER}"

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
	cp /tmp/conf/args /.docker4gis
