FROM golang:1.14.2

RUN go get -u golang.org/x/crypto/...

ENV CGO_ENABLED=0
ENV GOOS=linux

WORKDIR /usr/src/goproxy

ENTRYPOINT [ "go" ]
CMD [ "build", "-v", "-a", "-tags", "netgo", "-ldflags", "-w", "." ]
