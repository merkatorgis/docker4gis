#!/bin/bash

directive=$1

BASE=$BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_APP_DIR=${DOCKER_APP_DIR:-.}

# Compile a list of commands to run all repos' containers.

error() {
    echo "> ERROR: $1" >&2
    exit 1
}
pick_repo() {
    local item
    for item in "$@"; do
        [ "$item" = "$repo" ] && return 0
    done
    return 1
}
local_image_exists() {
    docker image tag "$1" "$1" >/dev/null 2>&1
}
add_repo() {

    # Skip test as this is not a repo, but the folder containing the tests to
    # run after the containers are started.
    [ "$repo" = test ] && return

    # Skip standalone components. A standalone component is a batch job -- an
    # on-demand loader or task -- rather than a service, so it must not be
    # started with the stack. It declares itself in its own .env, with the same
    # variable docker4gis proper uses:
    #
    #     # <component>/.env
    #     DOCKER4GIS_STANDALONE=1
    #
    # Sourced in a subshell, so a component's .env cannot leak variables into
    # this script. Tested BEFORE the tag lookup below, which is the point: a
    # component with no tag file reaches error(), and error() exits 1, taking
    # the whole of `run` with it. Without this skip, placing a batch job here
    # is a choice between breaking `run` outright (no tag file) and having a
    # container started for it on every `run` (with one) -- which is why such
    # jobs have had to idle on `CMD ["sleep", "infinity"]` and be reached with
    # `docker container exec`.
    #
    # build and push are unaffected and keep working: a standalone component
    # is built and pushed like any other, and is then run from its published
    # image with a plain `docker container run`, needing no clone.
    if [ -f "$repo_path"/.env ] && (
        DOCKER4GIS_STANDALONE=
        # shellcheck source=/dev/null
        . "$repo_path"/.env
        [ -n "$DOCKER4GIS_STANDALONE" ]
    ); then
        echo "Skipping standalone component $repo." >&2
        return
    fi

    echo "Fetching $repo..." >&2
    local image=$DOCKER_REGISTRY$DOCKER_USER/$repo
    local tag
    if [ "$directive" = dirty ] && local_image_exists "$image:latest"; then
        # use latest image _if_ it exists locally
        tag=latest
    else
        [ -f "$repo_path"/tag ] ||
            error "no tag file for '$repo'; was it pushed already?" &&
            tag=$(cat "$repo_path"/tag)
        # use local image _if_ it exists
        local_image_exists "$image:$tag" ||
            # otherwise, try to find it in the registry
            docker image pull "$image:$tag" >/dev/null ||
            error "image '$image:$tag' not found"
    fi
    if [ "$tag" ]; then
        echo "$image:$tag" >&2
        echo >&2
        # Use .docker4gis.sh to copy the image's own version of docker4gis out
        # of the image.
        echo "
            temp=\$(mktemp -d)
            dotdocker4gis=$BASE
            dotdocker4gis=\${dotdocker4gis:-\$(dirname \"\$0\")}
            dotdocker4gis=\$(\"\$dotdocker4gis\"/docker4gis/.docker4gis.sh \$temp '$image:$tag')
            (
                cd \"\$dotdocker4gis\"
                docker4gis/run.sh '$repo' '$tag'
            )
            rm -rf \$temp
            echo
        "
    else
        error "no tag for '$image'"
    fi
}
first_repo() {
    pick_repo postgis mysql
}
last_repo() {
    pick_repo proxy cron
}
for repo_path in "$DOCKER_APP_DIR"/*/; do
    repo=$(basename "$repo_path")
    first_repo && add_repo
done
for repo_path in "$DOCKER_APP_DIR"/*/; do
    repo=$(basename "$repo_path")
    first_repo || last_repo || add_repo
done
for repo_path in "$DOCKER_APP_DIR"/*/; do
    repo=$(basename "$repo_path")
    last_repo && add_repo
done

exit 0
