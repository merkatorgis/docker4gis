#!/bin/bash

extension=$1

if [ "$extension" = project ] || [ "$extension" = vssps ]; then
    shift
else
    extension=
fi

method=$1
path=$2
parameters=$3
data=$4

case $extension in
project)
    prefix=$AUTHORISED_COLLECTION_URI$SYSTEM_TEAMPROJECT/
    ;;
vssps)
    # Replace the dev host name with the vssps.dev host name.
    prefix=${AUTHORISED_COLLECTION_URI/@dev./@vssps.dev.}
    ;;
*)
    prefix=$AUTHORISED_COLLECTION_URI
    ;;
esac

[ -n "$parameters" ] && parameters="&$parameters"
api_version=${API_VERSION?}

_curl() {
    local uri="${prefix}_apis/$path?api-version=$api_version$parameters"
    curl --silent --fail-with-body -X "$method" \
        "$uri" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "$data"
}

if response=$(_curl); then
    result=$?
else
    result=$?
    if typeKey=$(node --print "($response).typeKey") &&
        [ "$typeKey" = VssInvalidPreviewVersionException ]; then
        # Retry with the preview version.
        api_version=$api_version-preview
        response=$(_curl)
        result=$?
    fi
fi

echo "$response"
exit "$result"
