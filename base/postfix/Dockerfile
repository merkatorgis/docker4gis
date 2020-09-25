FROM alpine:3.11.3

RUN apk update; apk add --no-cache \
	bash curl grep wget unzip sed \
	mailx postfix \
	openssl \
	shadow \
	ripmime

ENV PATH=/util:$PATH \
	DESTINATION=merkator-api.com

COPY conf/.plugins/bats /tmp/bats
RUN /tmp/bats/install.sh

COPY conf/.plugins/runner /tmp/runner
RUN /tmp/runner/install.sh

COPY conf/entrypoint /entrypoint
COPY conf/addmailbox.sh /usr/local/bin/addmailbox.sh
COPY conf/api.sh /usr/local/bin/api.sh
COPY conf/readmail.sh /usr/local/bin/readmail.sh

RUN	mkdir -p     /var/spool/postfix/ /var/spool/postfix/pid /var/mail; \
	chown root   /var/spool/postfix/ /var/spool/postfix/pid; \
	chmod a+rwxt /var/mail; \
	# Allow mail clients from connected Docker containers
	postconf -e mynetworks_style=subnet; \
	# Encrypt outgoing mail
	postconf -e smtp_tls_security_level=may; \
	# Disable SMTPUTF8, because libraries (ICU) are missing in alpine
	postconf -e smtputf8_enable=no; \
	# Update aliases database. It's not used, but postfix complains if the .db file is missing
	postalias /etc/postfix/aliases

EXPOSE 25

ENTRYPOINT ["/entrypoint"]
CMD ["postfix"]

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
	cp /tmp/conf/args /.docker4gis
