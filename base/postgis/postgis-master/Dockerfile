FROM docker.merkator.com/postgis/postgis:11-master-alpine

RUN apk update; apk add --no-cache \
	python py3-psycopg2 sudo

COPY conf/plsh /tmp/plsh
RUN /tmp/plsh/install.sh

COPY conf/pgjwt /tmp/pgjwt
RUN /tmp/pgjwt/install.sh

COPY conf/postgres /etc/postgresql

COPY conf/pgxn /tmp/pgxn
RUN /tmp/pgxn/install.sh

COPY conf/safeupdate /tmp/safeupdate
RUN /tmp/safeupdate/install.sh

COPY conf/plugins/runner /tmp/runner
RUN /tmp/runner/install.sh

COPY conf/plugins/pg /tmp/pg
RUN /tmp/pg/install.sh

COPY conf/plugins/mail /tmp/mail
RUN /tmp/mail/install.sh

COPY conf/entrypoint /entrypoint
COPY conf/init.sh /tmp/init.sh
COPY conf/conf.sh /tmp/conf.sh
COPY conf/onstart.sh /tmp/onstart.sh
COPY conf/subconf.sh /tmp/subconf.sh

COPY conf/util/schema.sh /usr/local/bin/schema.sh

COPY conf/mail /tmp/mail
COPY conf/web /tmp/web

ENTRYPOINT ["/entrypoint"]
CMD ["postgis"]

ONBUILD ADD conf /tmp/conf
