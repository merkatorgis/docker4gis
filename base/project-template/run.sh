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

# Run a command for each of a fixed list of REPOSITORY's.
each_repository() {
    for REPOSITORY in ^package cron; do
        "$@" || exit
    done
}

# Get an authenticated git origin URI for repo $REPOSITORY.
git_origin() {
    echo "$authorised_collection_uri$SYSTEM_TEAMPROJECT/_git/$REPOSITORY"
}

# Invoke the REST api to create a cross-repo main-branch policy to require
# resolution of all pull request comments.
az devops invoke \
    --route-parameters project="$SYSTEM_TEAMPROJECT" \
    --area policy \
    --resource configurations \
    --http-method POST \
    --in-file "$(dirname "$0")"/comment_requirements_policy.json

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

# Steps to create a repo named $REPOSITORY.
create_repository() {

    log "Repository $REPOSITORY"
    az repos show --repository="$REPOSITORY" >/dev/null 2>&1 && {
        echo "Skipping this repository, since it already exists."
        return 0
    }

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

# Execute the create_repository function for each repository.
each_repository create_repository

# Create a project directory
mkdir -p ~/project

git_clone() {
    log "Clone $REPOSITORY"
    cd ~/project &&
        git clone "$(git_origin)"
}

# Execute the git_clone function for each repository.
each_repository git_clone

dg() {
    npx docker4gis "$@"
}

dg_component() {
    local action='init|component'
    cd ~/project/"$REPOSITORY" &&
        log "dg $action $REPOSITORY" &&
        if [ "$REPOSITORY" = ^package ]; then
            echo n | dg init docker.merkator.com project
        else
            dg component
        fi &&
        log "Save $REPOSITORY changes" &&
        git add . &&
        git commit -m "docker4gis $action" &&
        git push origin
}

# Execute the dg_component function for each repository.
each_repository dg_component

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
