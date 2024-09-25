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

# Create a cross-repo main-branch policy to require resolution of all pull
# request comments.
az devops invoke \
    --route-parameters project="$SYSTEM_TEAMPROJECT" \
    --area policy \
    --resource configurations \
    --http-method POST \
    --in-file "$(dirname "$0")"/comment_requirements_policy.json

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
