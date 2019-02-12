#!/bin/bash

workspace=$(basename $(pwd))

cp -r ./workspace "$GEOSERVER_DATA_DIR/workspaces/${workspace}"
