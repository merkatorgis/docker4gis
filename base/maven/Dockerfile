FROM openjdk:8-alpine

RUN apk add maven

VOLUME /root/.m2

VOLUME /src

WORKDIR /src

ENTRYPOINT [ "mvn" ]
CMD [ "-Dfile.encoding=UTF-8", "clean", "package" ]

COPY conf/.docker4gis /.docker4gis
COPY run.sh /.docker4gis/run.sh
RUN touch /.docker4gis/args
