FROM alpine:3.7

RUN apk update; apk add --no-cache \
	ca-certificates wget

COPY conf /tmp/conf

COPY goproxy/goproxy /goproxy

RUN mv /tmp/conf/entrypoint/* /

EXPOSE 8080

ENTRYPOINT ["/entrypoint"]
CMD ["proxy"]
