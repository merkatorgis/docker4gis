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
