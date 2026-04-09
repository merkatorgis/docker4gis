#!/bin/bash

set -e
[ -n "$DEBUG" ] && set -x

triggers_definition='"triggers": [{
    "branchFilters": [],
    "pathFilters": [],
    "settingsSourceType": 2,
    "batchChanges": false,
    "maxConcurrentBuildsPerBranch": 1,
    "triggerType": "continuousIntegration"
}]'

continuous_integration_yaml=azure-pipeline-continuous-integration.yml
build_validation_yaml=azure-pipeline-build-validation.yml

for yaml in "$continuous_integration_yaml" "$build_validation_yaml"; do

    PR=
    triggers=
    name=${COMPONENT#^}
    name=${name:-$REPOSITORY}

    [ "$yaml" = "$build_validation_yaml" ] && PR=true

    if [ "$PR" ]; then
        name+=" PR"
    else
        triggers=$triggers_definition
    fi

    # Check if pipeline already exists; if so, reuse it.
    existing=$(/devops/rest.sh project GET build/definitions \
        "name=$(node --print "encodeURIComponent('$name')")")
    build_definition_id=$(node --print "($existing).count > 0 ? ($existing).value[0].id : 'new'")

    if [ "$build_definition_id" = new ]; then
        log Create pipeline "$name"
    else
        log "Pipeline $name exists"
        continue
    fi

    # Create the pipeline, a.k.a. build definition.
    build_definition=$(/devops/rest.sh project POST build/definitions '' "{
            \"name\": \"$name\",
            \"repository\": {
                \"type\": \"TfsGit\",
                \"name\": \"$REPOSITORY\"
            },
            \"process\": {
                \"yamlFilename\": \"${YAML_DIR:+$YAML_DIR/}$yaml\",
                \"type\": 2
            },
            \"variableGroups\": [ { \"id\": $VARIABLE_GROUP_ID } ],
            \"queue\": { \"name\": \"Azure Pipelines\" },
            $triggers
        }")
    build_definition_id=$(node --print "($build_definition).id")

    if [ "$PR" ]; then
        # Create a branch policy to require a successful build before merging.
        log Create branch policy "$name"
        path_filter_args=()
        [ -n "$YAML_DIR" ] && path_filter_args=(--path-filter "/components/$COMPONENT/*")
        response=$(az repos policy build create --blocking true \
            --build-definition-id "$build_definition_id" \
            --repository-id "$REPOSITORY_ID" \
            --branch main \
            --display-name "$name" \
            --enabled true \
            --manual-queue-only false \
            --queue-on-source-update-only false \
            --valid-duration 0 \
            "${path_filter_args[@]}")
    else
        # Permit the continuous integration pipeline to use the deployment
        # environments and service connections.
        for environment in TEST PRODUCTION; do
            pipelinePermissions() {
                local resource=$1

                log "Permit pipeline $name to use $resource $environment"

                case $resource in
                endpoint)
                    local area=serviceendpoint
                    local parameter_name=endpointNames
                    ;;
                environment)
                    local area=pipelines
                    local parameter_name=name
                    ;;
                esac

                local object
                object=$(/devops/rest.sh project GET "$area/$resource"s \
                    "$parameter_name=$environment")

                local resource_id
                resource_id=$(node --print "($object).value[0].id")

                area=pipelines/pipelinePermissions
                response=$(/devops/rest.sh project PATCH \
                    "$area/$resource/$resource_id" '' "{
                        \"pipelines\": [{
                            \"id\": $build_definition_id,
                            \"authorized\": true
                        }]
                    }")
            }

            pipelinePermissions endpoint

            [ -z "$YAML_DIR" ] || environment+=_SINGLE
            pipelinePermissions environment
        done
    fi
done

# We use `response=$(...)` to prevent the resonse from being echoed to the
# console.
response=${response:-}
