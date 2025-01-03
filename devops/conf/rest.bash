_rest_generic() {
    local method=$1
    local prefix=$2
    local path=$3
    local parameters=$4
    local data=$5

    [ -n "$parameters" ] && parameters="&$parameters"
    local uri="${prefix}_apis/$path?api-version=$API_VERSION$parameters"
    curl --silent -X "$method" \
        "$uri" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "$data"
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
