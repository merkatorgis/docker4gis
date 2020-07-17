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

function integer() {
    local key=$1
    local value=$2
    if ! [ "$value" -eq "$value" ]; then
        error "$key: $value is not an integer"
    fi
}

function positive_integer() {
    local key=$1
    local value=$2
    if ! [ "$value" -ge 0 ]; then
        error "$key: $value is not a positive integer"
    fi
}

function length() {
    local key=$1
    local value=$2
    local length=$3
    if ! [ "${#value}" -eq "$length" ]; then
        error "$key: $value is not $length characters long"
    fi
}

function positive_integer_length() {
    positive_integer "$1" "$2"
    length "$1" "$2" "$3"
}
