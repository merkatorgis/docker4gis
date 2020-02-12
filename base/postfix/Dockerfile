FROM alpine:3.11.3

RUN apk update; apk add --no-cache \
	bash curl grep wget unzip sed \
	mailx postfix \
	openssl \
	shadow \
	ripmime

ENV PATH=/util:$PATH \
	DESTINATION=merkator-api.com

ADD conf /tmp/conf

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
	postalias /etc/postfix/aliases; \
	mv /tmp/conf/entrypoint/* /; \
	mv /tmp/conf/util         /util; \
	/tmp/conf/plugins/runner/install.sh

EXPOSE 25

ENTRYPOINT ["/entrypoint"]
CMD ["postfix"]

ONBUILD ADD conf /tmp/conf
