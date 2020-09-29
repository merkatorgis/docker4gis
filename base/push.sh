#!/bin/bash
set -e

DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_APP_DIR=$DOCKER_APP_DIR

repo=$1
tag=$2

[ "$repo" ] || echo "Please pass the name of the component to push."
[ "$repo" ] || exit 1

dir=$DOCKER_APP_DIR/$repo
ls -d "$dir"/ >/dev/null || exit 1

integer() {
    [ "$1" -gt 0 ] 2>/dev/null
}

# Refuse an integer tag that is not higher than any integer package tag,
# so that we can use the given repo's tag as the tag for the updated package
# as well.
if [ "$repo" != .package ] && [ "$tag" ] && ! integer "$tag"; then
    [ "$tag" != latest ] &&
        echo "> WARNING: given tag ($tag) is neither 'latest' nor a positive integer number." &&
        read -rn 1 -p 'Type Y to continue anyway... ' answer && echo &&
        [ "$answer" = Y ] || exit 1
else
    [ -f "$DOCKER_APP_DIR"/.package/tag ] &&
        package_tag=$(cat "$DOCKER_APP_DIR"/.package/tag) &&
        integer "$package_tag" &&
        if [ "$tag" -le "$package_tag" ]; then
            echo "> ERROR: given tag ($tag) shoud be higher than current package's tag ($package_tag)."
            exit 1
        fi
fi

[ "$repo" = .package ] && repo=package
image=$DOCKER_REGISTRY$DOCKER_USER/$repo

docker image push "$image":latest
[ "$tag" ] || exit

docker image tag "$image":latest "$image":"$tag"
docker image push "$image":"$tag"
docker image rm -f "$image":latest

echo "$tag" >"$dir"/tag
echo "> Tag written to '$dir/tag'; remember to commit changes."
