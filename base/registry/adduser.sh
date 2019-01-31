#!/bin/bash
user="$1"
password="$2"

docker exec theregistry sh -c "htpasswd -Bbn $user $password >> /var/lib/registry/htpasswd"
