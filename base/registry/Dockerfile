FROM golang:1.15.2 as builder
WORKDIR /go/src/github.com/merkatorgis/docker4gis/goproxy
RUN go get -u golang.org/x/crypto/...
COPY goproxy/main.go .
RUN CGO_ENABLED=0 GOOS=linux go build -v -a -tags netgo -ldflags -w .

FROM alpine:3.12
COPY --from=builder /go/src/github.com/merkatorgis/docker4gis/goproxy/goproxy /

RUN apk update; apk add --no-cache \
	ca-certificates

COPY conf /tmp/conf

RUN mv /tmp/conf/entrypoint/* /

EXPOSE 443

ENTRYPOINT ["/entrypoint"]
CMD ["proxy"]
