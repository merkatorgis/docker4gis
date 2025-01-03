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
export -f log

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
    read -rp "Enter your DevOps project name : " SYSTEM_TEAMPROJECT
fi

# Read in the environment file.
# shellcheck source=/dev/null
source /devops/env_file

if [ -z "$PAT" ]; then
    doc_url="https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&toc=%2Fazure%2Fdevops%2Forganizations%2Ftoc.json&tabs=Windows#create-a-pat"
    message="Enter a Personal Access Token"
    message+=" of a user that is allowed to create a project - see $doc_url"
    read -rp "$message : " PAT
    # Save the PAT to the environment file.
    /devops/set.sh PAT "$PAT"
fi

default_value() {
    local name=$1
    local default=$2
    # If the value is not set, then set it to the default value.
    if [ -z "${!name}" ]; then
        # Save the default value to the environment file.
        /devops/set.sh "$name" "$default"
    fi
}

default_value VPN_POOL 'VPN Agent'
default_value DOCKER_REGISTRY docker.merkator.com
default_value SYSTEM_COLLECTIONURI https://dev.azure.com/merkatordev/

# Re-read the environment file, that now should contain all variables.
# shellcheck source=/dev/null
source /devops/env_file

# Set the default project and organisation for the Azure DevOps CLI.
az devops configure --defaults "project=$SYSTEM_TEAMPROJECT"
az devops configure --defaults "organization=$SYSTEM_COLLECTIONURI"

# Login to the Azure DevOps CLI.
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
    local repository_id

    log "Create repository $REPOSITORY" &&
        repository_id=$(az repos create --name "$REPOSITORY" \
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
        /devops/pipelines.sh \
            "$REPOSITORY" "$repository_id" "$variable_group_id" ||
        exit
done

# Create a cross-repository policy (if it doesn't exist) to require all PR
# comments to be roseolved before merging.
comment_requirements_policy='{
  "isBlocking": true,
  "isDeleted": false,
  "isEnabled": true,
  "isEnterpriseManaged": false,
  "revision": 1,
  "settings": {
      "scope": [
          {
              "matchKind": "Exact",
              "refName": "refs/heads/main",
              "repositoryId": null
          }
      ]
  },
  "type": {
      "displayName": "Comment requirements",
      "id": "c6a1889d-b943-4856-b76f-9e46bb6b0df2"
  }
}'
policy_query="[?settings.scope[0].repositoryId==null]"
policy_query+=" | [?type.displayName=='Comment requirements'].id"
existing_policy=$(az repos policy list --output tsv --query "$policy_query")
if [ -n "$existing_policy" ]; then
    log "Policy Comment requirements exists"
else
    log "Create Policy Comment requirements"
    rest_project POST policy/configurations '' "$comment_requirements_policy"
fi || exit

# Try to create the VPN Agent Pool if it doesn't exist in the project.
queueNames=$(node --print "encodeURIComponent('$VPN_POOL')")
queues=$(rest_project GET distributedtask/queues "queueNames=$queueNames")
if [ "$(node --print "($queues).count")" -gt 0 ]; then
    log Agent Pool "$VPN_POOL" exists in project
else
    query="[?name=='$VPN_POOL'].id"
    if pool_id=$(az pipelines pool list --output tsv --query "$query"); then
        if rest_project POST distributedtask/queues authorizePipelines=false "{
            \"name\": \"$VPN_POOL\",
            \"pool\": {
                \"id\": $pool_id
            }
        }"; then
            log Agent Pool "$VPN_POOL" added to project
        else
            log Failed to add Agent Pool "$VPN_POOL" to project
        fi
    else
        log Pool "$VPN_POOL" not found
    fi
fi

log Set permissions for the project build service

# Invoke the REST api manually to get the identity descriptor of the project
# build service, which we want to assign some permissions.
project_build_service_identity=$(rest_vssps GET identities \
    "searchFilter=AccountName&filterValue=$SYSTEM_TEAMPROJECTID")
project_build_service_descriptor=$(node --print \
    "($project_build_service_identity).value[0].descriptor")

security_namespace_git_repositories=2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87
# az devops security permission namespace show --output table \
#     --namespace-id $security_namespace_git_repositories
# Name                     Permission Description                                  Permission Bit
# -----------------------  ------------------------------------------------------  ----------------
# GenericRead              Read                                                    2
# GenericContribute        Contribute                                              4
# CreateTag                Create tag                                              32
# PolicyExempt             Bypass policies when pushing                            128
# 2 + 4 + 32 + 128 = 166
allow=166

# Invoke the REST api manually to allow the GenericRead, GenericContribute,
# CreateTag, PolicyExemptproject permissions to the project build service.
rest POST "AccessControlEntries/$security_namespace_git_repositories" '' "{
    \"token\": \"repoV2/$SYSTEM_TEAMPROJECTID/\",
    \"merge\": true,
    \"accessControlEntries\": [
        {
            \"descriptor\": \"$project_build_service_descriptor\",
            \"allow\": $allow
        }
    ]
}"
