#!/bin/bash

# Uncomment for debugging the commands that are issued:
# echo
# echo " -- $0 $* --"
# echo
# set -x

# Compiles a list of commands to run all components' containers.

# Either empty (we're creating the package image's run.sh script from the
# build.sh), or 'dirty' (we're running without a package image, in the dev env).
directive=$1

BASE=$BASE
DOCKER_BASE=$DOCKER_BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
package_docker_registry=$DOCKER_REGISTRY
package_docker_user=$DOCKER_USER

normalise_component_repo_name() {
    local value=$1

    value=$(basename "$value")
    if [ -n "$package_docker_user" ] && [[ "$value" == "$package_docker_user"-* ]]; then
        value=${value#"$package_docker_user"-}
    fi
    value=${value#docker4gis-}
    value=${value%%.*}
    value=${value#^}

    echo "$value"
}

# Use a temp dir to collect component name→version mappings.
temp_components=$(mktemp -d)

finish() {
    rm -rf "$temp_components"
    exit "${1:-0}"
}

error() {
    echo "> ERROR: $1" >&2
    finish 1
}

version_is_newer() {
    local candidate=$1
    local current=$2

    [ "$candidate" = "$current" ] && return 1
    [ "$(printf '%s\n%s\n' "$current" "$candidate" | sort -V | tail -n1)" = "$candidate" ]
}

prune_latest_runtime() {
    local repo=$1
    local image=$DOCKER_REGISTRY/$DOCKER_USER/$repo:latest
    local container=$DOCKER_USER-$repo
    [ "$repo" = proxy ] && container=docker4gis-proxy

    if old_image=$(docker container inspect --format='{{ .Config.Image }}' "$container" 2>/dev/null); then
        [ "$old_image" = "$image" ] && {
            docker container stop "$container" >/dev/null 2>&1 || true
            docker container rm "$container" >/dev/null 2>&1 || true
        }
    fi

    docker image rm -f "$image" >/dev/null 2>&1 || true
}

# In the monorepo, the ^package component lives at components/^package/.
# Sibling components are at ../../components/*/.
for comp_dir in ../../components/*/; do
    [ -d "$comp_dir" ] || continue
    comp_name=$(basename "$comp_dir")
    comp_repo=$(normalise_component_repo_name "$comp_name")
    # Skip the ^package component itself.
    [ "$comp_repo" = package ] && continue
    # Start a subshell to prevent overwriting environment variables.
    (
        DOCKER4GIS_VERSION=
        DOCKER_REGISTRY=$package_docker_registry
        DOCKER_USER=$package_docker_user
        DOCKER_REPO=

        comp_env="${comp_dir}.env"
        [ -f "$comp_env" ] || exit
        # shellcheck source=/dev/null
        . "$comp_env"

        [ "$DOCKER_REPO" ] || DOCKER_REPO=$comp_repo

        # Skip standalone components.
        [ -n "$DOCKER4GIS_STANDALONE" ] && exit
        # Must be a valid docker4gis component directory.
        [ "$DOCKER4GIS_VERSION" ] && [ "$DOCKER_REPO" ] || exit

        # Look for the version tracking file in ./components/ (relative to
        # the ^package dir). In local dev (`dirty`), refresh it from the
        # component's package.json, so `dg run` captures a tested set.
        tracking_dir=./components
        tracking_file="$tracking_dir/$DOCKER_REPO"
        if [ "$directive" = dirty ]; then
            mkdir -p "$tracking_dir" || exit
            package_json="$comp_dir/package.json"
            package_version=
            tracked_version=
            if [ -f "$package_json" ]; then
                package_version=$(node --print "require('$package_json').version" 2>/dev/null || true)
            fi
            [ -f "$tracking_file" ] && tracked_version=$(cat "$tracking_file")

            promote=
            if [ -n "$package_version" ] && [ "$package_version" != "0.0.0" ]; then
                if ! [ -f "$tracking_file" ]; then
                    promote=true
                elif [ -z "$tracked_version" ] || [ "$tracked_version" = latest ]; then
                    promote=true
                else
                    tracked_semver=${tracked_version#v}
                    [[ "$tracked_semver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] &&
                        version_is_newer "$package_version" "$tracked_semver" &&
                        promote=true
                fi
            fi

            if [ "$promote" = true ]; then
                version=v$package_version
                echo "$version" >"$tracking_file"
                prune_latest_runtime "$DOCKER_REPO"
            elif [ -f "$tracking_file" ]; then
                version=$(cat "$tracking_file")
            else
                version=latest
            fi
        elif [ -f "$tracking_file" ]; then
            version=$(cat "$tracking_file")
        else
            echo "> ERROR: version unknown for '$DOCKER_REPO'; run \`dg push\` in that component first" >&2
            exit 1
        fi

        # Add this component's version to the collection.
        echo "$version" >"$temp_components"/"$DOCKER_REPO"
    )
done

components=$temp_components

if ! ls "$components"/* >/dev/null 2>&1; then
    echo "Zero components." >&2
    finish 127
fi

local_image_exists() {
    docker image tag "$1" "$1" >/dev/null 2>&1
}

repo=
version=

add_repo() {

    echo "Fetching $repo..." >&2

    local image=$DOCKER_REGISTRY/$DOCKER_USER/$repo
    local tag

    if [ "$directive" = dirty ] && local_image_exists "$image:latest"; then
        # use latest image _if_ it exists locally
        tag=latest
    else
        if ! [ "$version" = latest ]; then
            tag=$version
        else
            if [ "$directive" = dirty ]; then
                error "no image for '$repo'; was it built already?"
            else
                error "version unknown for '$repo'; was it pushed already?"
            fi
        fi
        # Use local image _if_ it exists.
        local_image_exists "$image:$tag" ||
            # Otherwise, try to find it in the registry. Note that this is why
            # the build validation pipeline of the package repo has to log into
            # the docker registry.
            docker image pull "$image:$tag" >/dev/null ||
            error "image '$image:$tag' not found"
    fi

    if [ "$tag" ]; then
        echo "$image:$tag" >&2
        echo >&2
        echo "$("$DOCKER_BASE/.docker4gis/run" "$tag" "$repo") || exit"
        echo "echo"
    else
        error "no tag for '$image'"
    fi
}

# Test if current repo is one of the given repos.
pick_repo() {
    repo=$(basename "$repo_file")
    version=$(cat "$repo_file")
    local item
    for item in "$@"; do
        [ "$item" = "$repo" ] && return 0
    done
    return 1
}

first_repo() {
    pick_repo postgis mysql
}

last_repo() {
    pick_repo proxy cron
}

add_postgis_ddl() {
    [ "$repo" = postgis ] || return 0

    ddl_repo=postgis-ddl
    ddl_repo_file=$components/$ddl_repo
    [ -f "$ddl_repo_file" ] ||
        error "component '$ddl_repo' is required when 'postgis' is present; add a components/$ddl_repo component directory"

    repo=$ddl_repo
    version=$(cat "$ddl_repo_file")
    add_repo
    postgis_ddl_added=true
}

# Loop through all components and add those that should go first.
for repo_file in "$components"/*; do
    if first_repo; then
        add_repo
        add_postgis_ddl
    fi
done

# Loop through all components again and add those that should not go first or
# last.
for repo_file in "$components"/*; do
    first_repo || last_repo ||
        ([ "$repo" = postgis-ddl ] && [ -n "$postgis_ddl_added" ]) ||
        add_repo
done

# Loop through all components again and add those that should go last.
for repo_file in "$components"/*; do
    last_repo && add_repo
done

# Tidy up.
finish
