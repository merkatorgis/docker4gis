#!/bin/bash

# Stop if we're not a pipeline.
_=${TF_BUILD:?"This only works in an Azure DevOps pipeline."}

__header__() {
    set +x
    echo '---------------------------------------------------------------------'
    echo "$1"
    echo '---------------------------------------------------------------------'
    set -x
}

set -x

__header__ Setup

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

__header__ Execution

# Steps to create a repo named $REPOSITORY.
create_repository() {
    __header__ "Create repository $REPOSITORY"

    # Check if the repo exists, and skip if it does.
    az repos show --repository="$REPOSITORY" 2>&1 &&
        return 0

    # Create the new repo.
    az repos create --name "$REPOSITORY" &&
        # Initialise the new repo.
        (
            temp=$(mktemp --directory)
            cd "$temp" || exit
            git init &&
                git commit --allow-empty -m "initialise repository" &&
                git branch -m main &&
                git remote add origin "$(git_origin)" &&
                git push origin main
        ) &&
        # Set the repo's default branch to "main".
        az repos update --repository="$REPOSITORY" \
            --default-branch main
}

# Execute the create_repository function for each repository.
each_repository create_repository

__header__ Teardown

# Query the id of the repo to delete.
id=$(az repos show --repository="$SYSTEM_TEAMPROJECT" --query=id) &&
    # Trim surrouding "".
    eval "id=$id" &&
    [ "$id" ]

# Delete the repo by id.
az repos delete --id="$id" --yes

# Query the id of the pipeline to delete.
id=$(az pipelines show --name="$SYSTEM_TEAMPROJECT" --query=id) &&
    [ "$id" ]

# Delete the pipeline by id.
az pipelines delete --id="$id" --yes
