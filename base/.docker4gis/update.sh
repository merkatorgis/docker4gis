#!/bin/bash

tag=$1
if [ "$tag" = "" ]; then
    echo 'Please provide a tag.'
    exit 1
fi

log=$(mktemp)

finish() {
    code=$?
    cat "$log"
    rm "$log"
    exit "$code"
}

for file in "$DOCKER_BASE"/*; do
    # skip whatever is not a component directory
    [ -f "$file/run.sh" ] || continue

    dir=$file
    component=$(basename "$dir")
    echo
    echo '------------'
    echo "- $component"
    echo '------------'
    echo
    echo "$dir" >>"$log"
    echo -n "$component: " >>"$log"
    pushd "$dir" || finish
    ./build.sh &&
        docker image tag docker4gis/"$component":latest docker4gis/"$component":"$tag" &&
        docker image push docker4gis/"$component":"$tag" &&
        docker image push docker4gis/"$component":latest &&
        echo 'OK' >>"$log" &&
        echo >>"$log"
    popd || finish
done

finish
