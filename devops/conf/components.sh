#!/bin/bash

# Do not echo commands just yet, to prevent printing the PAT to the console.
# [ -n "$DEBUG" ] && set -x

project=$1
if [ "$project" = -p ] || [ "$project" = --project ]; then
    SYSTEM_TEAMPROJECT=${2:?Project name is required}
    shift 2
# If project starts with --project=, then extract the value.
elif [[ $project =~ ^--project= ]]; then
    SYSTEM_TEAMPROJECT=${project#--project=}
    shift
fi

# Write or update a key=value line in the root .env file (if mounted).
write_root_env() {
    local key=$1 value=$2
    [ -n "$ROOT_ENV_FILE" ] && [ -f "$ROOT_ENV_FILE" ] || return 0
    # Single-quote the value so spaces are safe and cut-based readers get the raw value.
    local quoted_value="'${value//\'/\'\\\'\'}'"
    if grep -q "^$key=" "$ROOT_ENV_FILE"; then
        # Use a temp file + cp (not sed -i) to avoid "Device or resource busy"
        # on Docker bind-mounted files, where rename(2) fails across mounts.
        local tmp
        tmp=$(mktemp)
        sed "s|^$key=.*|$key=$quoted_value|" "$ROOT_ENV_FILE" >"$tmp"
        cp "$tmp" "$ROOT_ENV_FILE"
        rm "$tmp"
    else
        printf '%s=%s\n' "$key" "$quoted_value" >>"$ROOT_ENV_FILE"
    fi
}

set_env() {
    local name=$1
    local message=$2
    local default=$3

    # Read current value from env_file if it exists
    current_value=""
    if [ -f /devops/env_file ]; then
        # shellcheck source=/dev/null
        source /devops/env_file
        current_value=${!name}
    fi

    # Use current value from env_file as default, or fall back to provided
    # default
    if [ -n "$current_value" ]; then
        if [ "$name" = PAT ]; then
            default="***"
        else
            default="$current_value"
        fi
        default_type="current"
    else
        default="$3"
        default_type="default"
    fi

    [ -n "$default" ] && message+=" (Enter for $default_type: $default)"

    # Always ask to provide the value, using current/provided default
    while true; do
        if [ "$name" = PAT ]; then
            # Do not echo the value entered.
            read -rsp "→  $message : " input_value
            echo
        else
            read -rp "→  $message : " input_value
        fi

        # When no input: use the displayed default, which is current_value if
        # set, otherwise the explicit fallback $3.
        if [ -z "$input_value" ]; then
            value="${current_value:-$3}"
        else
            value="$input_value"
        fi

        [ -n "$value" ] && break
    done

    if [ "$name" = SYSTEM_TEAMPROJECT ]; then
        # Assign the value to the variable.
        SYSTEM_TEAMPROJECT=$value
    else
        # Call the set.sh script to save the value to the env_file. Since set.sh
        # may amend the value given, we read the env_file back in later, to get
        # the proper value for each variable.
        /devops/set.sh "$name" "$value"
    fi
}

# SYSTEM_TEAMPROJECT: use DOCKER_USER from root .env without asking.
# Only prompt if we have no project name at all.
if [ -z "$SYSTEM_TEAMPROJECT" ]; then
    if [ -n "$DOCKER_USER" ]; then
        SYSTEM_TEAMPROJECT=$DOCKER_USER
    else
        set_env SYSTEM_TEAMPROJECT "DevOps Project"
    fi
fi

export SYSTEM_TEAMPROJECT

# Source env_file to pick up previously stored values (e.g. SYSTEM_COLLECTIONURI
# from a prior `dg devops set organisation ...`).
# shellcheck source=/dev/null
source /devops/env_file

# DEVOPS_ORGANISATION: when present in the current project's root .env, use it
# silently; otherwise ask upfront (before DevOps connectivity checks).
if [ "$ROOT_HAS_DEVOPS_ORGANISATION" = true ] && [ -n "$DEVOPS_ORGANISATION" ]; then
    /devops/set.sh organisation "$DEVOPS_ORGANISATION"
else
    # Suggest env_file value first, then root .env value, then default.
    set_env SYSTEM_COLLECTIONURI "DevOps Organisation" "${DEVOPS_ORGANISATION:-merkatordev}"
fi
source /devops/env_file

# Keep the root .env aligned with the selected organisation.
write_root_env DEVOPS_ORGANISATION "$SYSTEM_COLLECTIONURI"

doc_url="https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&toc=%2Fazure%2Fdevops%2Forganizations%2Ftoc.json&tabs=Windows#create-a-pat"
message="Personal Access Token (full access, incl. project creation)"

# PAT: always ask; never saved to root .env (it's a personal secret).
set_env PAT \
    "$message - see $doc_url"

# Login to the Azure DevOps CLI.
export AZURE_DEVOPS_EXT_PAT=$PAT

# Replace string to insert the "$PAT@" value between the (https):// and the
# host name in the URI (e.g. https://dev.azure.com/merkatordev/).
AUTHORISED_COLLECTION_URI=${SYSTEM_COLLECTIONURI/'://'/'://'$PAT@}
export AUTHORISED_COLLECTION_URI

refresh_org_settings() {
    # Keep authorised URI and Azure CLI defaults aligned with the selected org.
    AUTHORISED_COLLECTION_URI=${SYSTEM_COLLECTIONURI/'://'/'://'$PAT@}
    export AUTHORISED_COLLECTION_URI
    az devops configure --defaults "organization=$SYSTEM_COLLECTIONURI"
}

# DOCKER_REGISTRY, DEFAULT_POOL, and VPN_POOL are deferred to after the project
# clone; see the post-clone configuration block below.

if [ -z "$DEBUG" ]; then
    log() {
        echo '• ' "$@"
        sleep 1
    }
else
    log() {
        set +x
        echo '---------------------------------------------------------------------'
        echo "$@"
        echo '---------------------------------------------------------------------'
        # Prevent next commands echoing sooner.
        sleep 1
        set -x
    }
fi
export -f log

log Setup

# Set the default project and organisation for the Azure DevOps CLI.
refresh_org_settings
az devops configure --defaults "project=$SYSTEM_TEAMPROJECT"

# Configure git identity.
git config --global user.email 'pipeline@azure.com'
git config --global user.name 'Azure Pipeline'

# Set the default branch name to 'main', to prevent git from printing hints to
# the console.
git config --global init.defaultBranch main

get_project_id() {
    SYSTEM_TEAMPROJECTID=$(az devops project show \
        --project "$SYSTEM_TEAMPROJECT" \
        --query id \
        --output tsv)
    export SYSTEM_TEAMPROJECTID
    [ -n "$SYSTEM_TEAMPROJECTID" ]
}

# Get the project id (create the project if it doesn't exist). Exit on failure.
if get_project_id &>/dev/null; then
    log "Project $SYSTEM_TEAMPROJECT exists"
else
    log "Create Project $SYSTEM_TEAMPROJECT"
    # 2>/dev/null to prevent printing of harmless ERROR: VS800075: The project
    # with id 'vstfs:///Classification/TeamProject/f5e...87' does not exist, or
    # you do not have permission to access it.
    response=$(az devops project create --name "$SYSTEM_TEAMPROJECT" \
        2>/dev/null)
    # Make DevOps realise the new project exists.
    sleep 5
    get_project_id
fi || exit

log Check Project Administrators group membership

project_administrators_group=$(
    az devops security group list \
        --query "(graphGroups[?displayName=='Project Administrators'])[0]"
) &&
    descriptor=$(
        node --print "($project_administrators_group).descriptor"
    ) &&
    members=$(
        az devops security group membership list --id "$descriptor"
    ) &&
    me=$(
        /devops/rest.sh vssps GET profile/profiles/me
    ) &&
    email_address=$(
        node --print "($me).emailAddress"
    ) &&
    is_member=$(
        node --print "Object.values(($members)).some(m =>
            m.principalName === '$email_address' ||
            m.mailAddress === '$email_address'
        )"
    ) &&
    [ "$is_member" = true ] || exit

policy_exempt() {
    local allow_deny=$1

    # This value was set in the group membership check above.
    local project_administrators_group=$project_administrators_group

    policy_exemt_originId=${policy_exemt_originId:-$(
        node --print "($project_administrators_group).originId"
    )} &&
        policy_exemt_identity=${policy_exemt_identity:-$(
            /devops/rest.sh vssps GET identities \
                "identityIds=$policy_exemt_originId"
        )} &&
        policy_exemt_descriptor=${policy_exemt_descriptor:-$(
            node --print "($policy_exemt_identity).value[0].descriptor"
        )} &&
        /devops/set_permissions.sh 'Project Administrators' \
            "$policy_exemt_descriptor" "$allow_deny" PolicyExempt
}

# Steps to create a repo named $REPOSITORY.
create_repository() {

    log "Create repository $REPOSITORY" &&
        REPOSITORY_ID=$(az repos create --name "$REPOSITORY" \
            --query=id --output tsv) || return

    export REPOSITORY_ID

    log "Initialise repository $REPOSITORY" &&
        (
            temp=$(mktemp --directory) &&
                cd "$temp" &&
                git init &&
                git commit --allow-empty -m "initialise repository" &&
                git branch -m main &&
                git remote add origin "$AUTHORISED_COLLECTION_URI$SYSTEM_TEAMPROJECT/_git/$REPOSITORY" &&
                git push origin main
        ) || return

    log "Update repository $REPOSITORY: set default branch to 'main'" &&
        response=$(az repos update --repository="$REPOSITORY" \
            --default-branch main) || return
}

# Clone the repo $REPOSITORY.
git_clone() {
    log "Clone $REPOSITORY" &&
        mkdir -p ~/"$SYSTEM_TEAMPROJECT" &&
        cd ~/"$SYSTEM_TEAMPROJECT" &&
        /devops/git_origin.sh clone
}

# Ensure the default project repository has an initial commit on main.
ensure_repository_main_branch() {
    local origin
    origin="$AUTHORISED_COLLECTION_URI$SYSTEM_TEAMPROJECT/_git/$REPOSITORY"

    # Nothing to do when the repository already has at least one branch.
    if git ls-remote --heads "$origin" | grep -q .; then
        return 0
    fi

    log "Initialise repository $REPOSITORY with branch main" &&
        (
            temp=$(mktemp --directory) &&
                cd "$temp" &&
                git init &&
                git commit --allow-empty -m "initialise repository" &&
                git branch -m main &&
                git remote add origin "$origin" &&
                git push origin main
        ) || return

    log "Update repository $REPOSITORY: set default branch to 'main'" &&
        az repos update --repository="$REPOSITORY" \
            --default-branch main >/dev/null || return
}

# Create the Environments, each with an Approval check, and an SSH Service
# Connection. Do this before creating any pipelines referencing the
# environments, because that will create them automatically, and in a state that
# prevents us from adding the approval checks.
for environment in TEST PRODUCTION; do
    /devops/environment.sh "$environment" || exit
done

# Get the Variable Group id (create the Variable Group if it doesn't exist),
# which is needed for creating the Pipelines.
VARIABLE_GROUP_ID=$(az pipelines variable-group list \
    --query "[?name=='docker4gis'].id" \
    --output tsv)
if [ -n "$VARIABLE_GROUP_ID" ]; then
    log "Variable Group docker4gis exists"
else
    log Create variable group &&
        VARIABLE_GROUP_ID=$(az pipelines variable-group create \
            --name "docker4gis" \
            --authorize true \
            --variables "DOCKER_PASSWORD=changeit" \
            --query=id) || exit

    log Make variable DOCKER_PASSWORD secret &&
        response=$(az pipelines variable-group variable update \
            --group-id "$VARIABLE_GROUP_ID" \
            --name DOCKER_PASSWORD \
            --secret true) || exit
fi
export VARIABLE_GROUP_ID

# ------------------------------------------------------------------------------
# Begin of the main monorepo setup.
# ------------------------------------------------------------------------------

# The monorepo: use the default repository Azure created for the project.
# It is always named after the project.
REPOSITORY=$SYSTEM_TEAMPROJECT
export REPOSITORY

# Build the list of non-package components from args. Proxy is always included.
non_package_components=(proxy)
for c in "$@"; do
    IFS='=' read -r comp _ <<<"$c"
    comp=${comp,,}
    [[ " ${non_package_components[*]} " == *" $comp "* ]] ||
        non_package_components+=("$comp")
done

log "Components: package ${non_package_components[*]}"

# Temporarily allow "Bypass policies when pushing" for "Project Administrators".
policy_exempt allow || exit

repository_result=0

# The default repo (named after the project) always exists; just get its ID.
REPOSITORY_ID=$(az repos show --repository "$REPOSITORY" --query id --output tsv) &&
    export REPOSITORY_ID || repository_result=$?

# For a newly created project, the default repo can be empty. Initialise it so
# clone and subsequent setup always run on main.
if [ "$repository_result" = 0 ]; then
    ensure_repository_main_branch || repository_result=$?
fi

# Clone the repo if not already present locally.
if [ "$repository_result" = 0 ] && ! [ -d ~/"$SYSTEM_TEAMPROJECT/$REPOSITORY" ]; then
    git_clone || repository_result=$?
fi

# Post-clone configuration determination.
# Priority for repo-backed values: (1) cloned project .env, (2) current root
# .env passed in via run.sh, (3) prompt with defaults from /devops/env_file or
# built-in defaults.
cloned_env=~/"$SYSTEM_TEAMPROJECT/$REPOSITORY/.env"
read_cloned_env() {
    [ -f "$cloned_env" ] || return
    grep "^$1=" "$cloned_env" 2>/dev/null | cut -d= -f2- | sed "s/^'//;s/'$//"
}
cloned_docker_registry=$(read_cloned_env DOCKER_REGISTRY)
cloned_default_pool=$(read_cloned_env DEVOPS_DEFAULT_POOL)
cloned_vpn_pool=$(read_cloned_env DEVOPS_VPN_POOL)

if [ -n "$cloned_docker_registry" ]; then
    /devops/set.sh registry "$cloned_docker_registry"
elif [ "$ROOT_HAS_DOCKER_REGISTRY" = true ] && [ -n "$DOCKER_REGISTRY" ]; then
    /devops/set.sh registry "$DOCKER_REGISTRY"
else
    set_env DOCKER_REGISTRY "Docker Registry" "${DOCKER_REGISTRY:-docker.io}"
fi
source /devops/env_file
write_root_env DOCKER_REGISTRY "$DOCKER_REGISTRY"

if [ -n "$cloned_default_pool" ]; then
    /devops/set.sh default "$cloned_default_pool"
elif [ "$ROOT_HAS_DEVOPS_DEFAULT_POOL" = true ] && [ -n "$DEVOPS_DEFAULT_POOL" ]; then
    /devops/set.sh default "$DEVOPS_DEFAULT_POOL"
else
    set_env DEFAULT_POOL "Pipeline Agent Pool for general jobs" "${DEVOPS_DEFAULT_POOL:-Azure Pipelines}"
fi
source /devops/env_file
[ "$ROOT_HAS_DEVOPS_DEFAULT_POOL" != true ] && write_root_env DEVOPS_DEFAULT_POOL "$DEFAULT_POOL"

if [ -n "$cloned_vpn_pool" ]; then
    /devops/set.sh vpn "$cloned_vpn_pool"
elif [ "$ROOT_HAS_DEVOPS_VPN_POOL" = true ] && [ -n "$DEVOPS_VPN_POOL" ]; then
    /devops/set.sh vpn "$DEVOPS_VPN_POOL"
else
    set_env VPN_POOL "Pipeline Agent Pool for deployment jobs" "${DEVOPS_VPN_POOL:-VPN}"
fi
source /devops/env_file
[ "$ROOT_HAS_DEVOPS_VPN_POOL" != true ] && write_root_env DEVOPS_VPN_POOL "$VPN_POOL"

# Map stored pool names to the DEVOPS_ variables that docker4gis pipeline()
# uses when generating pipeline YAML files.
export DEVOPS_DEFAULT_POOL=$DEFAULT_POOL
export DEVOPS_VPN_POOL=$VPN_POOL

# Discover existing components from the cloned repo and add to the list.
if [ "$repository_result" = 0 ]; then
    repo_components_dir=~/"$SYSTEM_TEAMPROJECT/$REPOSITORY/components"
    if [ -d "$repo_components_dir" ]; then
        for comp_dir in "$repo_components_dir"/*/; do
            comp=$(basename "$comp_dir")
            # Skip ^package (handled separately) and duplicates.
            [[ "$comp" == "^package" ]] && continue
            [[ " ${non_package_components[*]} " == *" $comp "* ]] ||
                non_package_components+=("$comp")
        done
    fi
fi

refresh_components_from_repo() {
    local repo_components_dir
    repo_components_dir=~/"$SYSTEM_TEAMPROJECT/$REPOSITORY/components"
    [ -d "$repo_components_dir" ] || return 0

    local comp comp_dir
    for comp_dir in "$repo_components_dir"/*/; do
        comp=$(basename "$comp_dir")
        # Skip ^package (handled separately) and duplicates.
        [[ "$comp" == "^package" ]] && continue
        [[ " ${non_package_components[*]} " == *" $comp "* ]] ||
            non_package_components+=("$comp")
    done
}

# Initialise the package and components in the monorepo.
if [ "$repository_result" = 0 ]; then
    (
        cd ~/"$SYSTEM_TEAMPROJECT/$REPOSITORY" || exit 1
        needs_push=false

        # Initialise the package at the repo root.
        if ! [ -f .env ]; then
            log "dg init in $REPOSITORY"
            (cd .. && dg init "$REPOSITORY" "$DOCKER_REGISTRY") || exit 1
            needs_push=true
        fi

        # Write/update DEVOPS_* vars near the top of .env, directly below
        # DOCKER_USER, so dg devops keeps this block ordered and current.
        write_devops_env_block() {
            local env_file=.env
            local org pool_default pool_vpn
            org="'${SYSTEM_COLLECTIONURI//\'/\'\\\'\'}'"
            pool_default="'${DEFAULT_POOL//\'/\'\\\'\'}'"
            pool_vpn="'${VPN_POOL//\'/\'\\\'\'}'"
            local temp
            temp=$(mktemp) || return 1

            local inserted=
            while IFS= read -r line || [ -n "$line" ]; do
                case "$line" in
                DEVOPS_ORGANISATION=* | DEVOPS_DEFAULT_POOL=* | DEVOPS_VPN_POOL=*)
                    continue
                    ;;
                esac

                printf '%s\n' "$line" >>"$temp"

                if [ -z "$inserted" ] && [[ "$line" == DOCKER_USER=* ]]; then
                    printf '%s\n' "DEVOPS_ORGANISATION=$org" >>"$temp"
                    printf '%s\n' "DEVOPS_DEFAULT_POOL=$pool_default" >>"$temp"
                    printf '%s\n' "DEVOPS_VPN_POOL=$pool_vpn" >>"$temp"
                    inserted=true
                fi
            done <"$env_file"

            if [ -z "$inserted" ]; then
                printf '%s\n' "DEVOPS_ORGANISATION=$org" >>"$temp"
                printf '%s\n' "DEVOPS_DEFAULT_POOL=$pool_default" >>"$temp"
                printf '%s\n' "DEVOPS_VPN_POOL=$pool_vpn" >>"$temp"
            fi

            if cmp -s "$env_file" "$temp"; then
                rm "$temp"
            else
                mv "$temp" "$env_file"
                needs_push=true
            fi
        }
        write_devops_env_block || exit 1
        unset -f write_devops_env_block

        # Initialise each component in components/<name>/.
        for component in "${non_package_components[@]}"; do
            if ! [ -d "components/$component" ]; then
                log "dg component $component in $REPOSITORY"
                dg component "$component" &&
                    cd ~/"$SYSTEM_TEAMPROJECT/$REPOSITORY" || exit 1
                needs_push=true
            fi
        done

        # Re-scan components after creation to include any auto-added
        # dependencies (e.g. postgis-ddl added by dg component postgis).
        refresh_components_from_repo

        if $needs_push; then
            git add . &&
                git commit -m "docker4gis init/component" &&
                git push origin &&
                # Set the default branch to main now that the first commit exists.
                az repos update --repository="$REPOSITORY" \
                    --default-branch main >/dev/null || exit 1
        fi
    ) || repository_result=$?
fi

# The initialisation block runs in a subshell, so refresh once more here to
# ensure the parent shell list includes any auto-added components.
if [ "$repository_result" = 0 ]; then
    refresh_components_from_repo
fi

# Create pipelines for the ^package component.
if [ "$repository_result" = 0 ]; then
    COMPONENT="^package" YAML_DIR="components/^package" /devops/pipelines.sh || repository_result=$?
fi

# Create pipelines for each component (YAML files under components/<name>/).
for component in "${non_package_components[@]}"; do
    [ "$repository_result" = 0 ] || break
    COMPONENT=$component YAML_DIR="components/$component" /devops/pipelines.sh ||
        repository_result=$?
done

# Undo temporarily allow "Bypass policies when pushing" for "Project
# Administrators".
policy_exempt deny || exit

# Exit if any step failed - but only after undoing the policy change.
[ "$repository_result" = 0 ] || {
    log "Error: non-zero repository_result: $repository_result"
    exit "$repository_result"
}

# ------------------------------------------------------------------------------
# End of the main monorepo setup.
# ------------------------------------------------------------------------------

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
    response=$(/devops/rest.sh project POST policy/configurations '' \
        "$comment_requirements_policy")
fi || exit

# Set permissions for the Project Build Service.
project_build_service_identity=$(/devops/rest.sh vssps GET identities \
    "searchFilter=AccountName&filterValue=$SYSTEM_TEAMPROJECTID") &&
    project_build_service_descriptor=$(node --print \
        "($project_build_service_identity).value[0].descriptor") &&
    /devops/set_permissions.sh 'Project Build Service' \
        "$project_build_service_descriptor" allow \
        GenericRead GenericContribute CreateTag PolicyExempt || exit

# Try to create the Agent Pool if it doesn't exist in the project.
create_pool() {
    local pool_name=$1
    local queueNames
    queueNames=$(node --print "encodeURIComponent('$pool_name')") &&
        local queues &&
        queues=$(/devops/rest.sh project GET distributedtask/queues \
            "queueNames=$queueNames") &&
        if [ "$(node --print "($queues).count")" -gt 0 ]; then
            log Agent Pool "$pool_name" exists in project
        else
            local query="[?name=='$pool_name'].id"
            local pool_id
            if pool_id=$(az pipelines pool list --output tsv --query "$query"); then
                local response
                if response=$(/devops/rest.sh project POST \
                    distributedtask/queues authorizePipelines=true "{
                        \"name\": \"$pool_name\",
                        \"pool\": {
                            \"id\": $pool_id
                        }
                    }"); then
                    log Agent Pool "$pool_name" added to project
                else
                    log Error: failed to add Agent Pool "$pool_name" to project
                    return 1
                fi
            else
                log Error: pool "$pool_name" not found
                return 1
            fi
        fi

    permit_pool "$pool_name" "$pool_id"
}

# Grant permission for the project to use the specified agent pool.
permit_pool() {
    local pool_name=$1
    local pool_id=$2

    log "Grant permission to use Agent Pool $pool_name"

    # Get the queue ID from the project's queues
    local queueNames
    queueNames=$(node --print "encodeURIComponent('$pool_name')")
    local queues
    queues=$(/devops/rest.sh project GET distributedtask/queues \
        "queueNames=$queueNames")

    local queue_count
    queue_count=$(node --print "($queues).count" 2>/dev/null)

    if [ "$queue_count" != "1" ]; then
        log "Error: Expected 1 queue for pool '$pool_name', found $queue_count"
        return 1
    fi

    local queue_id
    queue_id=$(node --print "($queues).value[0].id" 2>/dev/null)

    if [ -z "$queue_id" ]; then
        log "Error: Could not get queue ID for pool '$pool_name'"
        return 1
    fi

    # Get all pipelines that need permission to use this pool
    local pipelines
    pipelines=$(az pipelines list --query "[].{id:id}" --output json 2>/dev/null) || {
        log "Error: Could not get pipelines list, skipping agent pool permission grant"
        return 1
    }

    if [ -z "$pipelines" ] || [ "$pipelines" = "[]" ]; then
        log "No pipelines found, skipping agent pool permission grant"
        return 0
    fi

    # Create the pipeline permissions payload that matches the web UI request
    local pipeline_permissions
    pipeline_permissions=$(node --print "
        try {
            const pipelines = $pipelines;
            const permissions = {
                pipelines: pipelines.map(p => ({
                    id: p.id,
                    authorized: true
                }))
            };
            JSON.stringify(permissions);
        } catch (e) {
            console.log('{}');
        }
    " 2>/dev/null)

    if [ -z "$pipeline_permissions" ] || [ "$pipeline_permissions" = "{}" ]; then
        log "Error: Could not format pipeline permissions"
        return 1
    fi

    local response
    if response=$(/devops/rest.sh project PATCH \
        "pipelines/pipelinePermissions/queue/$queue_id" '' \
        "$pipeline_permissions"); then
        return 0
    else
        log "Error: Failed to grant pipeline permissions for Agent Pool '$pool_name'"
        echo "- API Response: $response"
        echo "- Queue ID: $queue_id"
        echo "- Pipeline Permissions JSON: $pipeline_permissions"
        return 1
    fi
}

# Create agent pools and grant permissions (after all pipelines have been
# created)
create_pool "$DEFAULT_POOL" || exit
create_pool "$VPN_POOL" || exit

# We use `response=$(...)` to prevent the resonse from being echoed to the
# console.
response=${response:-}

log "OK - ${SYSTEM_COLLECTIONURI%/}/$SYSTEM_TEAMPROJECT"
