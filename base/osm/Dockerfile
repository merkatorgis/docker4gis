FROM overv/openstreetmap-tile-server:1.5.0

ENV UPDATES enabled
ENV ALLOW_CORS enabled

ENV DOWNLOAD_PBF https://download.geofabrik.de/europe/belgium-latest.osm.pbf
ENV DOWNLOAD_POLY https://download.geofabrik.de/europe/belgium.poly

COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["osm"]

EXPOSE 80 5432

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
    cp /tmp/conf/args /.docker4gis
