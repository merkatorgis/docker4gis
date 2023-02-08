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

log() {
    echo "• $1..."
}

# Use npm to increment our version; see
# https://docs.npmjs.com/cli/v9/commands/npm-version. Npm assumes semantic
# versioning; we don't actually do that - instead, we just keep incrementing the
# PATCH version (see https://semver.org). With git-tag-version set to false,
# apparently npm version not only skips the tag, but also the commit.
log "Bumping our version"
npm config set git-tag-version false
version=$(npm version patch)
echo "$version"

# Base components have templates with Dockerfiles stating the image's version.
log "Upgrading any templates"
here=$(dirname "$0")
"$here/upgrade_templates.sh" "$version"

# (Re)build the image, to include any upgraded templates.
log "Building the image"
"$(dirname "$0")"/../docker4gis build

image=$DOCKER_REGISTRY/$DOCKER_USER/$DOCKER_REPO

log "Tagging the image"
docker image tag "$image":latest "$image":"$version"

log "Pushing $image:$version"
docker image push "$image":"$version"

# This is important for base components (and harmless for extension components),
# since the default base image tag sugested in `dg component` is `latest`.
log "Pushing $image:latest"
docker image push "$image":latest

# This is for when the push is done from a local development environment, to
# signal `dg run` that this image is no longer in development, and it should
# start the new versioned image.
log "Removing the local 'latest' image"
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

tag="$version"
message="$tag [skip ci]"

log "Committing the version"
git add .
git commit -m "$message"

log "Pushing the commit"
push

log "Tagging the git repo"
git tag -a "$tag" -f -m "$message"

log "Pushing the tag"
push "$tag" -f
