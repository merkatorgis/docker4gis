#!/bin/bash

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

project=$1
shift
if [ "$project" = -p ] || [ "$project" = --project ]; then
    SYSTEM_TEAMPROJECT=${2:?Project name is required}
    shift
# If project starts with --project=, then extract the value.
elif [[ $project =~ ^--project= ]]; then
    SYSTEM_TEAMPROJECT=${project#--project=}
fi

if [ -z "$SYSTEM_TEAMPROJECT" ]; then
    read -rp \
        "Enter your DevOps project name : " \
        SYSTEM_TEAMPROJECT
fi

# shellcheck source=/dev/null
source /devops/env_file

if [ -z "$PAT" ]; then
    doc_url="https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&toc=%2Fazure%2Fdevops%2Forganizations%2Ftoc.json&tabs=Windows#create-a-pat"
    read -rp \
        "Enter a project manager's Personal Access Token - see $doc_url : " \
        PAT
    /devops/set.sh PAT "$PAT"
fi

default_value() {
    local name=$1
    local default=$2
    # If the value is not set, then set it to the default value.
    if [ -z "${!name}" ]; then
        # Set the run-time value.
        eval "export ${!name}=$default"
        # Save the default value to the environment file.
        /devops/set.sh "$name" "$default"
    fi
}

default_value VPN_POOL 'VPN Agent'
default_value DOCKER_REGISTRY docker.merkator.com
default_value SYSTEM_COLLECTIONURI https://dev.azure.com/merkatordev/

az devops configure --defaults "project=$SYSTEM_TEAMPROJECT"
az devops configure --defaults "organization=$SYSTEM_COLLECTIONURI"

echo "$PAT" | az devops login

# Replace string to insert the \"\$PAT@\" value between the (https):// and
# the host name in the URI (e.g. https://dev.azure.com/merkatordev/).
AUTHORISED_COLLECTION_URI=${SYSTEM_COLLECTIONURI/'://'/'://'$PAT@}
export AUTHORISED_COLLECTION_URI

# Configure git identity.
git config --global user.email 'pipeline@azure.com'
git config --global user.name 'Azure Pipeline'

# Get an authenticated git origin URI for repo $REPOSITORY.
git_origin() {
    echo "$AUTHORISED_COLLECTION_URI$SYSTEM_TEAMPROJECT/_git/$REPOSITORY"
}

dg() {
    npx --yes docker4gis@latest "$@"
}

# Export rest functions.
# shellcheck source=/dev/null
source /devops/rest.bash

get_project_id() {
    SYSTEM_TEAMPROJECTID=$(az devops project show \
        --project "$SYSTEM_TEAMPROJECT" \
        --query id \
        --output tsv)
}

# Get the project id (create the project if it doesn't exist). Exit on failure.
if get_project_id &>/dev/null; then
    log "Project $SYSTEM_TEAMPROJECT exists"
else
    az devops project create --name "$SYSTEM_TEAMPROJECT"
    get_project_id
    log "Project $SYSTEM_TEAMPROJECT created"
fi || exit

export SYSTEM_TEAMPROJECTID

components=("$@")
# Make components lowercase.
components=("${components[@],,}")

# Add all components if none are specified.
if [ ${#components[@]} -eq 0 ]; then
    components=("${components[@]}" angular)
    components=("${components[@]}" cron)
    components=("${components[@]}" dynamic)
    components=("${components[@]}" geoserver)
    components=("${components[@]}" postfix)
    components=("${components[@]}" postgis)
    components=("${components[@]}" postgrest)
    components=("${components[@]}" serve)
    components=("${components[@]}" swagger)
    components=("${components[@]}" tomcat)
fi

components_always=(^package proxy)
# Remove components that are always created.
for component in "${components_always[@]}"; do
    components=("${components[@]/$component/}")
done
# Add components that are always created.
components=("${components_always[@]}" "${components[@]}")

log Components: "${components[@]}"

# Steps to create a repo named $REPOSITORY.
create_repository() {
    log "Create repository $REPOSITORY" &&
        local repository_id=$(az repos create --name "$REPOSITORY" \
            --query=id --output tsv) || return

    log "Initialise repository $REPOSITORY" &&
        (
            temp=$(mktemp --directory) &&
                cd "$temp" &&
                git init &&
                git commit --allow-empty -m "initialise repository" &&
                git branch -m main &&
                git remote add origin "$(git_origin)" &&
                git push origin main
        ) || return

    log "Update repository $REPOSITORY: set default branch to 'main'" &&
        az repos update --repository="$REPOSITORY" \
            --default-branch main || return

    echo "$repository_id"
}

# Clone the repo $REPOSITORY.
git_clone() {
    log "Clone $REPOSITORY" &&
        mkdir -p ~/"$SYSTEM_TEAMPROJECT" &&
        cd ~/"$SYSTEM_TEAMPROJECT" &&
        git clone "$(git_origin)"
}

# Create a docker4gis component for the repo $REPOSITORY.
dg_init_component() {
    log "dg init/component $COMPONENT in $REPOSITORY" &&
        cd ~/"$SYSTEM_TEAMPROJECT/$REPOSITORY" &&
        if [ "$REPOSITORY" = ^package ]; then
            dg init "$DOCKER_REGISTRY"
        else
            dg component "$COMPONENT"
        fi || return

    log "Push $REPOSITORY changes" &&
        git add . &&
        git commit -m "docker4gis init/component" &&
        git push origin
}

# Create the Environments, each with an Approval check, and an SSH Service
# Connection. Do this before creating any pipelines referencing the
# environments, because that will create them automatically, and in a state that
# prevents us from adding the approval checks.
for environment in TEST PRODUCTION; do
    /devops.environment.sh "$environment"
done || exit

# Get the variable group id (create the variable group if it doesn't exist),
# which is needed for creating the pipelines.
variable_group_id=$(/devops/variable_group.sh) || exit

# Create the repositories, components, and pipelines.
for component_repository in "${components[@]}"; do
    # Split component_repository into component and repository, using = as the separator.
    IFS='=' read -r COMPONENT REPOSITORY <<<"$component_repository"
    REPOSITORY=${REPOSITORY:-$COMPONENT}
    # Skip if the repository already exists.
    if az repos show --repository "$REPOSITORY" &>/dev/null; then
        log "Repository $REPOSITORY already exists"
        continue
    fi
    # Create the repository, its docker4gis component, and its pipelines.
    repository_id=$(create_repository) &&
        git_clone &&
        dg_init_component &&
        /devops/pipelines.sh "$repository_id" "$variable_group_id"
done || exit

# Try to create the VPN Agent Pool if it doesn't exist in the project.
queueNames=$(node --print "encodeURIComponent('$VPN_POOL')")
queues=$(rest_project GET distributedtask/queues "queueNames=$queueNames")
if [ "$(node --print "($queues).count")" -gt 0 ]; then
    log Agent Pool "$VPN_POOL" exists in project
else
    log Create Agent Pool "$VPN_POOL" in project
    pool_id=$(az pipelines pool list --output tsv \
        --query "[?name=='$VPN_POOL'].id") &&
        rest_project POST distributedtask/queues authorizePipelines=false "{
        \"name\": \"$VPN_POOL\",
        \"pool\": {
            \"id\": $pool_id
        }
    }"
fi
