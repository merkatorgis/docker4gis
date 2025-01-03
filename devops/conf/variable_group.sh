#!/bin/bash

variable_group_id=$(az pipelines variable-group list \
    --query "[?name=='docker4gis'].id" \
    --output tsv)

if [ -n "$variable_group_id" ]; then
    log "Variable Group docker4gis exists"
else
    set -e

    log Create variable group
    variable_group_id=$(az pipelines variable-group create \
        --name "docker4gis" \
        --authorize true \
        --variables "DOCKER_PASSWORD=changeit" \
        --query=id)

    log Make variable DOCKER_PASSWORD secret
    az pipelines variable-group variable update \
        --group-id "$variable_group_id" \
        --name DOCKER_PASSWORD \
        --secret true
fi

echo "$variable_group_id"
