#!/bin/bash
user="$1"
password="$2"

sudo docker exec theregistry sh -c "htpasswd -Bbn $user $password >> /var/lib/registry/htpasswd"
