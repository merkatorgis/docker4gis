FROM openjdk:8-alpine

RUN apk add maven

VOLUME /root/.m2

VOLUME /src

WORKDIR /src

ENTRYPOINT [ "mvn" ]
CMD [ "-Dfile.encoding=UTF-8", "clean", "package" ]
