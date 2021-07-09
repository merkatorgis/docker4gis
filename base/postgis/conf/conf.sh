#!/bin/bash

conf() {
	echo "$1 = '$2'" >>"$CONFIG_FILE"
}

cp "$CONFIG_FILE.template" "$CONFIG_FILE"

# https://www.pgadmin.org/docs/pgadmin4/latest/debugger.html
[ "$DOCKER_ENV" = DEVELOPMENT ] || [ "$DOCKER_ENV" = DEV ] && conf shared_preload_libraries plugin_debugger

[ "$POSTGRES_LOG_STATEMENT" ] && conf log_statement "$POSTGRES_LOG_STATEMENT"

echo "
	export POSTGIS_USER=${POSTGRES_USER}
	export POSTGIS_PASSWORD=${POSTGRES_PASSWORD}
	export POSTGIS_ADDRESS=${CONTAINER}
	export POSTGIS_DB=${POSTGRES_DB}
	export POSTGIS_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${CONTAINER}/${POSTGRES_DB}
" >/secrets/.pg

if [ -f /secrets/postgresql.key -a -f /secrets/postgresql.crt -a -f /secrets/root.key -a -f /secrets/root.crt -a -f /secrets/server.key -a -f /secrets/server.crt ]; then
	cp /secrets/postgresql.key /secrets/postgresql.crt /secrets/root.key /secrets/root.crt /secrets/server.key /secrets/server.crt /etc/postgresql/
	cp /secrets/postgresql.key /secrets/postgresql.crt /secrets/root.crt /certificates/
	chmod og+r /certificates/*
else
	echo "[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
basicConstraints = CA:true
subjectAltName=email:move" >>/etc/ssl/openssl.cnf

	# CA
	openssl req -new -nodes -text -out root.csr \
		-keyout root.key -subj "/CN=root.merkator.com"
	openssl x509 -req -in root.csr -text -days 3650 \
		-extfile /etc/ssl/openssl.cnf -extensions v3_ca \
		-signkey root.key -out root.crt

	# Client
	openssl req -new -nodes -text -out postgresql.csr \
		-keyout postgresql.key -subj "/CN=$POSTGRES_USER"
	openssl x509 -req -in postgresql.csr -text -days 365 \
		-CA root.crt -CAkey root.key -CAcreateserial \
		-out postgresql.crt

	cp postgresql.key postgresql.crt root.crt /certificates/

	# Server
	openssl req -new -nodes -text -out server.csr \
		-keyout server.key -subj /CN=postgis.merkator.com
	openssl x509 -req -in server.csr -text -days 365 \
		-CA root.crt -CAkey root.key -CAcreateserial \
		-out server.crt

	mv *.crt *.key /etc/postgresql/
	cp /etc/postgresql/*.crt /etc/postgresql/*.key /secrets/
fi

chown -R postgres:postgres /etc/postgresql/ /secrets/*
chmod og-rwx /etc/postgresql/*.key /secrets/root.key /secrets/server.*
