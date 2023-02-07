#!/bin/bash
set -e

DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_REPO=$DOCKER_REPO

error() {
    echo "Error: $1"
    exit 1
}

if ! [ "$DOCKER_REPO" ]; then
    error "DOCKER_REPO variable not set"
fi

check_git_clear() {
    git fetch
    if git status --short --branch | grep behind; then
        error "git branch is behind; please sync"
    fi
    if [ "$(git status --short)" ]; then
        error "git repo has pending changes"
    fi
}
check_git_clear

version=1
if [ -f version ]; then
    # read current version from file
    version=$(cat version)
    if ! [ "$version" -gt 0 ] 2>/dev/null; then
        error "version must contain a positive integer number"
    fi
    # increment
    ((version++))
fi

log() {
    echo "• $1..."
}

image=$DOCKER_REGISTRY/$DOCKER_USER/$DOCKER_REPO

log "Tagging image"
docker image tag "$image":latest "$image":"$version"

log "Pushing image"
docker image push "$image":"$version"

log "Removing local 'latest' image"
docker image rm -f "$image":latest

push() {
    if ! git push origin "$@"; then
        result=$?
        if [ "$result" = 128 ]; then
            # support a non-remote context (e.g. pipeline)
            echo "INFO: remote not found: origin"
            return 0
        else
            exit "$result"
        fi
    fi
}

# stop if git repo received new changes
check_git_clear

log "Writing version file"
echo "$version" >version

log "Upgrading any templates"
here=$(dirname "$0")
"$here/upgrade_templates.sh" "$version"

log "Committing version"
message="version $version [skip ci]"
git add .
git commit -m "$message"

log "Pushing the commit"
push

log "Tagging the git repo"
tag="v$version"
git tag -a "$tag" -f -m "$message"

log "Pushing the tag"
push "$tag" -f
