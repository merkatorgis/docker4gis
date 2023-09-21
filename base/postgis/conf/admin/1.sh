#!/bin/bash

pushd schema/1

pg.sh -f admin.sql

popd

chown :postgres -R "/fileport/$DOCKER_USER/dump"
chmod g+w -R "/fileport/$DOCKER_USER/dump"
