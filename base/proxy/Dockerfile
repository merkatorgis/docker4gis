FROM alpine:3.7

RUN apk update; apk add --no-cache \
	ca-certificates wget

COPY conf/certificates /tmp/conf/certificates
COPY conf/entrypoint /entrypoint
COPY conf/conf.sh /conf.sh
COPY goproxy/goproxy /goproxy

EXPOSE 80 443

ENTRYPOINT ["/entrypoint"]
CMD ["proxy"]

ONBUILD ADD conf /tmp/conf
