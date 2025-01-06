_rest_generic() {
    local method=$1
    local prefix=$2
    local path=$3
    local parameters=$4
    local data=$5

    [ -n "$parameters" ] && parameters="&$parameters"
    local api_version=${API_VERSION?}

    _curl() {
        local uri="${prefix}_apis/$path?api-version=$api_version$parameters"
        curl --silent --fail-with-body -X "$method" \
            "$uri" \
            -H 'Accept: application/json' \
            -H 'Content-Type: application/json' \
            -d "$data"
    }

    local result
    if response=$(_curl); then
        result=$?
    else
        result=$?
        local typeKey
        if typeKey=$(node --print "($response).typeKey") &&
            [ "$typeKey" = VssInvalidPreviewVersionException ]; then
            # Retry with the preview version.
            api_version=$api_version-preview
            response=$(_curl)
            result=$?
        fi
    fi

    echo "$response"
    return "$result"
}
export -f _rest_generic

rest() {
    local method=$1
    local path=$2
    local parameters=$3
    local data=$4

    local prefix=$AUTHORISED_COLLECTION_URI
    _rest_generic "$method" "$prefix" "$path" "$parameters" "$data"
}
export -f rest

rest_project() {
    local method=$1
    local path=$2
    local parameters=$3
    local data=$4

    local prefix=$AUTHORISED_COLLECTION_URI$SYSTEM_TEAMPROJECT/
    _rest_generic "$method" "$prefix" "$path" "$parameters" "$data"
}
export -f rest_project

# Replace the dev host name with the vssps.dev host name.
authorised_collection_uri_vssps=${AUTHORISED_COLLECTION_URI/@dev./@vssps.dev.}

rest_vssps() {
    local method=$1
    local path=$2
    local parameters=$3
    local data=$4

    local prefix=$authorised_collection_uri_vssps
    _rest_generic "$method" "$prefix" "$path" "$parameters" "$data"
}
export -f rest_vssps
