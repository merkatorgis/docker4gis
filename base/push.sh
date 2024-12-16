#!/bin/bash
set -e

[ "$1" = --no-save ] && {
    no_save=true
    shift
}

for build_arg in "$@"; do
    suffix=$suffix-$build_arg
done

_=${DOCKER_BASE:?'Must have DOCKER_BASE set.'}
_=${DOCKER_REGISTRY:?'Must have DOCKER_REGISTRY set.'}
_=${DOCKER_USER:?'Must have DOCKER_USER set.'}
_=${DOCKER_REPO:?'Must have DOCKER_REPO set.'}

error() {
    echo "Error: $1" >&2
    exit 1
}

if ! "$DOCKER_BASE"/check_git_clear.sh; then
    exit 1
fi

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
# Save the "bare" version for tagging the git repo.
tag=$version
# Include any build_args in the image's tag.
[ -n "$suffix" ] && version=$version$suffix
echo "$version"

# Base components have templates with Dockerfiles stating the image's version.
log "Upgrading any templates"
"$DOCKER_BASE"/upgrade_templates.sh "$version"

# (Re)build the image, to include any upgraded templates.
log "Building the image"
# $DOCKER4GIS_COMMAND without quotes, since it can be a command with parameters.
$DOCKER4GIS_COMMAND build "$@"

image=$DOCKER_REGISTRY/$DOCKER_USER/$DOCKER_REPO

log "Tagging the image"
docker image tag "$image":latest "$image":"$version"

log "Pushing $image:$version"
docker image push "$image":"$version"

[ "$no_save" = true ] && {
    # Undo all changes.
    git reset --hard
    exit
}

# This is important for base components (and harmless for extension components),
# since the default base image tag sugested in `dg component` is `latest`.
log "Pushing $image:latest"
docker image push "$image":latest

push() {
    if ! git push origin "$@"; then
        result=$?
        if [ "$result" = 128 ]; then
            # Support a non-remote context (e.g. pipeline).
            echo "INFO: remote not found: origin"
            return 0
        else
            exit "$result"
        fi
    fi
}

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
