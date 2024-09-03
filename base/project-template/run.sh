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
