FROM merkatorgis/postgis

RUN apk update; apk add --no-cache \
	bash curl wget unzip grep sed

COPY conf /tmp/conf

RUN /tmp/conf/include/gs/install.sh

RUN	mv /tmp/conf/cron.sh /util/; \
	mkdir -p /util/cron; \
	mv /tmp/conf/startup.sh /util/cron/; \
	mv /tmp/conf/entrypoint/* /

ENV PATH=/util:$PATH

ENTRYPOINT ["/entrypoint"]
CMD ["cron"]
