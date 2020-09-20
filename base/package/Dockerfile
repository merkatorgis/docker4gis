FROM alpine:3.12

COPY conf/utils /docker4gis
COPY build.sh /docker4gis/build.sh
COPY run.sh /docker4gis/run.sh

RUN echo '#!/bin/bash' > /docker4gis/args.sh && \
    chmod +x /docker4gis/args.sh
