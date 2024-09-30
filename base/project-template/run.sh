#!/bin/bash

# Stop if we're not a pipeline.
_=${TF_BUILD:?"This only works in an Azure DevOps pipeline."}

log() {
    set +x
    echo '---------------------------------------------------------------------'
    echo "$@"
    echo '---------------------------------------------------------------------'
    # Prevent next commands echoing sooner.
    sleep 1
    set -x
}

set -x

log Setup

# Set Azure CLI authentication.
export AZURE_DEVOPS_EXT_PAT=$PAT

# Replace string to insert the \"\$PAT@\" value between the (https):// and
# the host name in the URI (e.g. https://dev.azure.com/merkatordev/).
authorised_collection_uri=${SYSTEM_COLLECTIONURI/'://'/'://'$PAT@}

# Replace the dev host name with the vssps.dev host name.
authorised_collection_uri_vssps=${authorised_collection_uri/@dev./@vssps.dev.}

# Configure git identity.
git config --global user.email 'pipeline@azure.com'
git config --global user.name 'Azure Pipeline'

# Set Azure CLI defaults for organization and project.
az devops configure --defaults "organization=$SYSTEM_COLLECTIONURI"
az devops configure --defaults "project=$SYSTEM_TEAMPROJECT"

dg() {
    npx docker4gis "$@"
}

# Run a command for each of a fixed list of REPOSITORY's.
each_repository() {
    for REPOSITORY in ^package cron dynamic geoserver postfix postgis postgrest proxy serve swagger tomcat; do

        REPOSITORY_ID=$(az repos show --repository="$REPOSITORY" --query=id)
        # Trim surrouding "".
        eval "REPOSITORY_ID=$REPOSITORY_ID"

        "$@" || exit
    done
}

# Get an authenticated git origin URI for repo $REPOSITORY.
git_origin() {
    echo "$authorised_collection_uri$SYSTEM_TEAMPROJECT/_git/$REPOSITORY"
}

# Steps to create a repo named $REPOSITORY.
create_repository() {
    log "Create repository $REPOSITORY"
    az repos create --name "$REPOSITORY" &&
        log "Initialise repository $REPOSITORY" &&
        (
            temp=$(mktemp --directory)
            cd "$temp" || exit
            git init &&
                git commit --allow-empty -m "initialise repository" &&
                git branch -m main &&
                git remote add origin "$(git_origin)" &&
                git push origin main
        ) &&
        log "Update repository $REPOSITORY: set default branch to 'main'" &&
        az repos update --repository="$REPOSITORY" \
            --default-branch main
}

# Clone the repo $REPOSITORY.
git_clone() {
    log "Clone $REPOSITORY"
    mkdir -p ~/project &&
        cd ~/project &&
        git clone "$(git_origin)"
}

# Create a docker4gis component for the repo $REPOSITORY.
dg_component() {
    local action=component
    if [ "$REPOSITORY" = ^package ]; then
        action=init
        local registry=docker.merkator.com
    fi
    cd ~/project/"$REPOSITORY" &&
        log "dg $action $REPOSITORY" &&
        echo n | dg "$action" "$registry" &&
        log "Save $REPOSITORY changes" &&
        git add . &&
        git commit -m "docker4gis $action" &&
        git push origin
}

# Create the pipelines for the repo $REPOSITORY.
create_pipelines() {

    # Create variable group if not exists.
    [ "$variable_group_id" ] || {
        log Create variable group
        variable_group_id=$(az pipelines variable-group create \
            --name "docker4gis" \
            --authorize true \
            --variables "DOCKER_PASSWORD=$(DOCKER_PASSWORD)" \
            --query=id)

        log Make variable DOCKER_PASSWORD secret
        az pipelines variable-group variable update \
            --group-id "$variable_group_id" \
            --name DOCKER_PASSWORD \
            --secret true
    }

    pipeline() {
        local name=$1
        local yaml=$2

        [ "$yaml" = azure-pipeline-build-validation.yml ] &&
            local PR=true

        log Create pipeline "$name"

        # Create the pipeline, a.k.a. build definition.
        build_definition_id=$(az pipelines create --name "$name" \
            --skip-first-run \
            --repository "$REPOSITORY" \
            --repository-type tfsgit \
            --branch main \
            --yaml-path "$yaml" \
            --query=id)

        # Disable continuous integration for the PR pipeline. But this doesn't
        # work...
        [ "$PR" ] &&
            local triggers='"triggers": [],'

        # Link the build definition to the variable group.
        curl --silent -X PUT \
            "$authorised_collection_uri$SYSTEM_TEAMPROJECTID/_apis/build/definitions/$build_definition_id?api-version=7.1" \
            -H 'Accept: application/json' \
            -H 'Content-Type: application/json' \
            -d "{
                \"id\": $build_definition_id,
                \"name\": \"$name\",
                \"process\": {
                    \"yamlFilename\": \"$yaml\"
                },
                \"repository\": {
                    \"name\": \"$REPOSITORY\",
                    \"type\": \"TfsGit\",
                },	
                \"revision\": 1,
                $triggers
                \"variableGroups\": [
                    {
                        \"id\": $variable_group_id
                    }
                ]
            }"

        # Newline after curl output.
        echo

        # Create a policy to require a successful build before merging.
        [ "$PR" ] && az repos policy build create --blocking true \
            --build-definition-id "$build_definition_id" \
            --repository-id "$REPOSITORY_ID" \
            --branch main \
            --display-name "$name" \
            --enabled true \
            --manual-queue-only false \
            --queue-on-source-update-only false \
            --valid-duration 0
    }

    pipeline "$REPOSITORY" \
        azure-pipeline-continuous-integration.yml

    pipeline "$REPOSITORY PR" \
        azure-pipeline-build-validation.yml
}

# Execute the create_repository function for each repository.
each_repository create_repository

# Execute the git_clone function for each repository.
each_repository git_clone

# Execute the dg_component function for each repository.
each_repository dg_component

# Execute the create_pipeline function for each repository.
each_repository create_pipelines

log Create a project-wide policy to require resolution of all comments in a pull request

# Invoke the REST api to create a cross-repo main-branch policy to require
# resolution of all pull request comments.
az devops invoke \
    --route-parameters project="$SYSTEM_TEAMPROJECT" \
    --area policy \
    --resource configurations \
    --http-method POST \
    --in-file "$(dirname "$0")"/comment_requirements_policy.json

log Set permissions for the project build service

# Invoke the REST api manually to get the identity descriptor of the project
# build service, which we want to assign some permissions.

curl --silent -X GET \
    "${authorised_collection_uri_vssps}_apis/identities?api-version=7.1&searchFilter=AccountName&filterValue=$SYSTEM_TEAMPROJECTID" \
    -H 'Accept: application/json' \
    >./project_build_service_identity.json

project_build_service_descriptor=$(
    node --print "require('./project_build_service_identity.json').value[0].descriptor"
)

security_namespace_git_repositories=2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87

# az devops security permission namespace show \
#     --namespace-id $security_namespace_git_repositories \
#     --output table
# Name                     Permission Description                                  Permission Bit
# -----------------------  ------------------------------------------------------  ----------------
# GenericRead              Read                                                    2
# GenericContribute        Contribute                                              4
# CreateTag                Create tag                                              32
# PolicyExempt             Bypass policies when pushing                            128
# 2 + 4 + 32 + 128 = 166

# Invoke the REST api manually to allow the GenericRead, GenericContribute,
# CreateTag, PolicyExemptproject permissions to the project build service.

curl --silent -X POST \
    "${authorised_collection_uri}_apis/AccessControlEntries/$security_namespace_git_repositories?api-version=7.1" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "{
        \"token\": \"repoV2/$SYSTEM_TEAMPROJECTID/\",
        \"merge\": true,
        \"accessControlEntries\": [
            {
                \"descriptor\": \"$project_build_service_descriptor\",
                \"allow\": 166
            }
        ]
    }"

log Create pipeline Environment TEST

curl --silent -X POST \
    "${authorised_collection_uri}$SYSTEM_TEAMPROJECT/_apis/pipelines/environments?api-version=7.1" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "{
        \"name\": \"TEST\"
    }"

log Create SSH Service Connection TEST

az devops service-endpoint create \
    --service-endpoint-configuration "$(dirname "$0")"/ssh_service_endpoint.json

log Delete project template repository

# Query the id of the repo to delete.
id=$(az repos show --repository="$SYSTEM_TEAMPROJECT" --query=id) &&
    # Trim surrouding "".
    eval "id=$id" &&
    [ "$id" ]

# Delete the repo by id.
az repos delete --id="$id" --yes

log Delete project template pipeline

# Query the id of the pipeline to delete.
id=$(az pipelines show --name="$SYSTEM_TEAMPROJECT" --query=id) &&
    [ "$id" ]

# Delete the pipeline by id.
az pipelines delete --id="$id" --yes
