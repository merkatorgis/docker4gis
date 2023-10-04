#!/bin/bash

pushd schema/"$(basename "$0" .sh)"

pg.sh -f admin.sql

popd

chown :postgres -R "/fileport/$DOCKER_USER/dump"
chmod g+w -R "/fileport/$DOCKER_USER/dump"
