FROM docker4gis/postgis:11-alpine

RUN apk update; apk add --no-cache \
	bash curl wget unzip grep sed

ADD conf /tmp/conf

RUN /tmp/conf/.plugins/gs/install.sh

RUN	mv /tmp/conf/cron.sh /util/; \
	mkdir -p /util/cron; \
	mv /tmp/conf/startup.sh /util/cron/; \
	mv /tmp/conf/entrypoint/* /

ENV PATH=/util:$PATH

ENTRYPOINT ["/entrypoint"]
CMD ["cron"]

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
	cp /tmp/conf/args /.docker4gis
