#!/bin/bash

set -ex

triggers_definition='"triggers": [{
    "branchFilters": [],
    "pathFilters": [],
    "settingsSourceType": 2,
    "batchChanges": false,
    "maxConcurrentBuildsPerBranch": 1,
    "triggerType": "continuousIntegration"
}]'

for yaml in \
    azure-pipeline-continuous-integration.yml \
    azure-pipeline-build-validation.yml; do

    [ "$yaml" = azure-pipeline-build-validation.yml ] &&
        PR=true

    name=$REPOSITORY
    [ "$PR" ] && name="$name PR"

    log Create pipeline "$name"

    [ "$PR" ] || triggers=$triggers_definition

    # Create the pipeline, a.k.a. build definition.
    build_definition=$(/devops/rest.sh project POST build/definitions '' "{
        \"name\": \"$name\",
        \"repository\": {
            \"type\": \"TfsGit\",
            \"name\": \"$REPOSITORY\"
        },
        \"process\": {
            \"yamlFilename\": \"$yaml\",
            \"type\": 2
        },
        \"variableGroups\": [ { \"id\": $VARIABLE_GROUP_ID } ],
        \"queue\": { \"name\": \"Azure Pipelines\" },
        $triggers
    }")
    echo "$build_definition"

    build_definition_id=$(node --print "($build_definition).id")

    pipelinePermissions() {
        local resource_type=$1
        local resource_id=$2

        log "Permit pipeline $name to use $resource_type $environment"

        /devops/rest.sh project PATCH \
            "pipelines/pipelinePermissions/$resource_type/$resource_id" '' "{
                \"pipelines\": [{
                    \"id\": $build_definition_id,
                    \"authorized\": true
                }]
            }"
    }

    get_object_id_by_name() {
        local path=$1
        local parameter_name=$2
        object=$(/devops/rest.sh project GET "$path" \
            "$parameter_name=$environment")
        node --print "($object).value[0].id"
    }

    # Permit the continuous integration pipeline to use the deployment
    # environments and service connections.
    [ "$PR" ] || {
        for environment in TEST PRODUCTION; do
            # Find the service connection id by name.
            id=$(get_object_id_by_name serviceendpoint/endpoints endpointNames)
            # Permit the pipeline to use the service connection.
            pipelinePermissions endpoint "$id"

            # Different environment for non-package repositories.
            [ "$REPOSITORY" = ^package ] || environment+=_SINGLE

            # Find the environment id by name.
            id=$(get_object_id_by_name pipelines/environments name)
            # Permit the pipeline to use the environment.
            pipelinePermissions environment "$id"
        done
    }

    # Create a policy to require a successful build before merging.
    [ "$PR" ] && {
        log Create build policy "$name"
        az repos policy build create --blocking true \
            --build-definition-id "$build_definition_id" \
            --repository-id "$REPOSITORY_ID" \
            --branch main \
            --display-name "$name" \
            --enabled true \
            --manual-queue-only false \
            --queue-on-source-update-only false \
            --valid-duration 0
    }
done
