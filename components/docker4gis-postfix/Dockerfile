FROM alpine:3.21.2

RUN apk update; apk add --no-cache \
    bash curl grep wget unzip sed \
    mailx postfix \
    openssl \
    shadow \
    ripmime

# Install the bats plugin.
COPY conf/.plugins/bats /tmp/bats
RUN /tmp/bats/install.sh

# Install the runner plugin.
COPY conf/.plugins/runner /tmp/runner
RUN /tmp/runner/install.sh

# Install local tools.
COPY conf/*.sh /usr/local/bin/

ENV DESTINATION=merkator-api.com

RUN	mkdir -p     /var/spool/postfix/ /var/spool/postfix/pid /var/mail; \
    chown root   /var/spool/postfix/ /var/spool/postfix/pid; \
    chmod a+rwxt /var/mail; \
    # Allow mail clients from connected Docker containers
    postconf -e mynetworks_style=subnet; \
    # Encrypt outgoing mail
    postconf -e smtp_tls_security_level=may; \
    # Disable SMTPUTF8, because libraries (ICU) are missing in alpine
    postconf -e smtputf8_enable=no; \
    # Update aliases database. It's not used, but postfix complains if the .db
    # file is missing
    postalias /etc/postfix/aliases

EXPOSE 25

# Allow configuration before things start up.
COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["postfix"]

# Make this image work with dg build & dg push.
COPY conf/.docker4gis /.docker4gis
COPY build.sh run.sh /.docker4gis/

# Set environment variables.
ONBUILD ARG DOCKER_REGISTRY
ONBUILD ENV DOCKER_REGISTRY=$DOCKER_REGISTRY
ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER=$DOCKER_USER
ONBUILD ARG DOCKER_REPO
ONBUILD ENV DOCKER_REPO=$DOCKER_REPO

# Make this an extensible base component; see
# https://github.com/merkatorgis/docker4gis/tree/npm-package/docs#extending-base-components.
COPY template /template/
