#!/bin/bash

repository_name=$1
repository_id=$2
variable_group_id=$3

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

    name=$repository_name
    [ "$PR" ] && name="$name PR"

    log Create pipeline "$name"

    [ "$PR" ] || triggers=$triggers_definition

    # Create the pipeline, a.k.a. build definition.
    build_definition=$(rest_project POST build/definitions '' "{
        \"name\": \"$name\",
        \"repository\": {
            \"type\": \"TfsGit\",
            \"name\": \"$repository_name\"
        },
        \"process\": {
            \"yamlFilename\": \"$yaml\",
            \"type\": 2
        },
        \"variableGroups\": [ { \"id\": $variable_group_id } ],
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
            --repository-id "$repository_id" \
            --branch main \
            --display-name "$name" \
            --enabled true \
            --manual-queue-only false \
            --queue-on-source-update-only false \
            --valid-duration 0
    }
done
