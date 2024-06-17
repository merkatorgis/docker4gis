#!/bin/bash

conf() {
	echo "$1 = '$2'" >>"$CONFIG_FILE"
}

cp "$CONFIG_FILE.template" "$CONFIG_FILE"

# https://www.pgadmin.org/docs/pgadmin4/latest/debugger.html
[ "$DOCKER_ENV" = DEVELOPMENT ] || [ "$DOCKER_ENV" = DEV ] && conf shared_preload_libraries plugin_debugger

[ "$POSTGRES_LOG_STATEMENT" ] && conf log_statement "$POSTGRES_LOG_STATEMENT"

# Provision a directory on the Docker host to store generated certificates for
# reuse by future containers.
secrets=/fileport/secrets
mkdir -p "$secrets"
chmod go-rwx "$secrets"

# Test if all certificate files are available on the host.
if ! [ -f "$secrets"/"$POSTGRES_USER".key ] || ! [ -f "$secrets"/"$POSTGRES_USER".crt ] || ! [ -f "$secrets"/root.key ] || ! [ -f "$secrets"/root.crt ] || ! [ -f "$secrets"/server.key ] || ! [ -f "$secrets"/server.crt ]; then
	# Configure openssl.
	echo "[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
basicConstraints = CA:true
subjectAltName=email:move" >>/etc/ssl/openssl.cnf

	# CA root certificate.
	openssl req -new -nodes -text -out root.csr \
		-keyout root.key -subj "/CN=root.merkator.com"
	openssl x509 -req -in root.csr -text -days 3650 \
		-extfile /etc/ssl/openssl.cnf -extensions v3_ca \
		-signkey root.key -out root.crt

	# Client certificate request.
	openssl req -new -nodes -text -out "$POSTGRES_USER".csr \
		-keyout "$POSTGRES_USER".key -subj "/CN=$POSTGRES_USER"
	# Cliet certificate.
	openssl x509 -req -in "$POSTGRES_USER".csr -text -days 365 \
		-CA root.crt -CAkey root.key -CAcreateserial \
		-out "$POSTGRES_USER".crt

	# Provide the client certificates on a bind-mounted host directory.
	cp "$POSTGRES_USER".key "$POSTGRES_USER".crt root.crt /certificates/

	# Server certificate request.
	openssl req -new -nodes -text -out server.csr \
		-keyout server.key -subj /CN=postgis.merkator.com
	# Server certificate.
	openssl x509 -req -in server.csr -text -days 365 \
		-CA root.crt -CAkey root.key -CAcreateserial \
		-out server.crt

	# Move all certificates to the proper directory in the container.
	mv -- *.crt *.key /etc/postgresql/
	# Also save the certificates for reuse to the volume.
	cp /etc/postgresql/*.crt /etc/postgresql/*.key "$secrets"/
else
	# Copy the existing certificates from the volume to the proper directory in
	# the container.
	cp "$secrets"/"$POSTGRES_USER".key "$secrets"/"$POSTGRES_USER".crt "$secrets"/root.key "$secrets"/root.crt "$secrets"/server.key "$secrets"/server.crt /etc/postgresql/
	# Make sure the client certificates on the bind-mounted host directory match
	# the ones in use by the database.
	cp "$secrets"/"$POSTGRES_USER".key "$secrets"/"$POSTGRES_USER".crt "$secrets"/root.crt /certificates/
	# Render the client certificates readable for the client.
	chmod go+r /certificates/*
fi

# Ensure proper ownership.
chown -R postgres:postgres /etc/postgresql/
# Ensure properly limited permissions.
chmod go-rwx /etc/postgresql/*.key
