FROM golang:1.25@sha256:3760478c76cfe25533e06176e983e7808293895d48d15d0981c0cbb9623834e7 AS builder

WORKDIR /go/src/github.com/merkatorgis/docker4gis/goproxy
COPY goproxy/* ./
RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux go build -v -a -tags netgo -ldflags -w .

FROM alpine:3.12@sha256:c75ac27b49326926b803b9ed43bf088bc220d22556de1bc5f72d742c91398f69

COPY --from=builder /go/src/github.com/merkatorgis/docker4gis/goproxy/goproxy /

RUN apk update; apk add --no-cache \
    ca-certificates

COPY conf/certificates /certificates

# Allow configuration before things start up.
COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["proxy"]

