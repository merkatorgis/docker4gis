#!/bin/bash
set -e

DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_APP_DIR=$DOCKER_APP_DIR

repo=$1
tag=$2

[ "$repo" ] || echo "Please pass the name of the component to push."
[ "$repo" ] || exit 1

[ "$tag" = latest ] && tag=

dir=$DOCKER_APP_DIR/$repo
ls -d "$dir"/ >/dev/null || exit 1

integer() {
    [ "$1" -gt 0 ] 2>/dev/null
}

# Refuse an integer tag that is not higher than any integer package tag,
# so that we can use the given repo's tag as the tag for the updated package
# as well.
[ "$tag" ] && [ "$repo" != .package ] && if ! integer "$tag"; then
    echo "> WARNING: given tag ($tag) is not a positive integer number."
    read -rn 1 -p 'Continue anyway? [yN] ' answer && echo
    [ "$answer" = y ] || exit 1
else
    [ -f "$DOCKER_APP_DIR"/.package/tag ] &&
        package_tag=$(cat "$DOCKER_APP_DIR"/.package/tag) &&
        integer "$package_tag" &&
        if [ "$tag" -le "$package_tag" ]; then
            echo "> WARNING: given tag ($tag) is not higher than current package's tag ($package_tag)."
            read -rn 1 -p 'Continue anyway? [yN] ' answer && echo
            [ "$answer" = y ] || exit 1
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
