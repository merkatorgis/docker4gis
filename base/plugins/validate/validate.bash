# To use these input validation functions,
# include in a bash command af follows:
# # shellcheck source=/dev/null
# source ~/.validate.bash
# Default error number is 2.

ERR_INVALID_INPUT=${1:-2}

function error() {
    echo "ERR_INVALID_INPUT" "$1"
    exit "$ERR_INVALID_INPUT"
}

function exists() {
    if ! [ -e "$1" ]; then
        error "$1 not found"
    fi
}

function file() {
    if ! [ -f "$1" ]; then
        error "$1 is not a file"
    fi
}

function directory() {
    if ! [ -d "$1" ]; then
        error "$1 is not a directory"
    fi
}

function readable() {
    if ! [ -r "$1" ]; then
        error "$1 is not readable"
    fi
}

function writable() {
    if ! [ -w "$1" ]; then
        error "$1 is not writable"
    fi
}

function executable() {
    if ! [ -x "$1" ]; then
        error "$1 is not executable"
    fi
}

function readable_file() {
    readable "$1"
    file "$1"
}

function length() {
    local key=$1
    local value=$2
    local length=$3
    if ! [ "${#value}" -eq "$length" ]; then
        error "$key: $value is not $length characters long"
    fi
}

function integer() {
    local key=$1
    local value=$2
    if ! [ "$value" -eq "$value" ]; then
        error "$key: $value is not an integer"
    fi
}

function integer_min() {
    local key=$1
    local value=$2
    local min=$3
    if ! [ "$value" -ge "$min" ]; then
        error "$key: $value is less than $min"
    fi
}

function integer_max() {
    local key=$1
    local value=$2
    local max=$3
    if ! [ "$value" -le "$max" ]; then
        error "$key: $value is greater than $max"
    fi
}

function integer_min_max() {
    local key=$1
    local value=$2
    local min=$3
    local max=$4
    integer_min "$key" "$value" "$min"
    integer_max "$key" "$value" "$max"
}

function integer_min_max_length() {
    local key=$1
    local value=$2
    local min=$3
    local max=$4
    local length=$5
    integer_min_max "$key" "$value" "$min" "$max"
    length "$key" "$value" "$length"
}
