FROM alpine:3.7

RUN apk update; apk add --no-cache \
	ca-certificates wget

COPY certificates /tmp/conf/certificates
COPY entrypoint /entrypoint
COPY conf.sh /conf.sh
COPY goproxy/goproxy /goproxy

EXPOSE 80 443

ENTRYPOINT ["/entrypoint"]
CMD ["proxy"]

ONBUILD ADD conf /tmp/conf
ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER="${DOCKER_USER}"
