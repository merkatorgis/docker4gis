FROM alpine:3.7

RUN apk update; apk add --no-cache \
	ca-certificates wget

COPY goproxy/goproxy /goproxy
COPY conf/certificates /certificates
COPY conf/entrypoint /entrypoint
COPY conf/conf.sh /conf.sh

EXPOSE 80 443

ENTRYPOINT ["/entrypoint"]
CMD ["proxy"]

ONBUILD COPY conf /tmp/conf
ONBUILD COPY conf/certificates /certificates
