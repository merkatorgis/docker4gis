# To use these input validation functions,
# include in a bash command af follows:
# # shellcheck source=/dev/null
# source ~/.validate.bash
# Default error number is 2.

ERR_INVALID_INPUT=${1:-2}

function error() {
    local key=$1
    local value=$2
    echo "ERR_INVALID_INPUT" "- $key:" "$value"
    exit "$ERR_INVALID_INPUT"
}

function exists() {
    local key=$1
    local value=$2
    if ! [ -e "$value" ]; then
        error "$key" "$value not found"
    fi
}

function file() {
    local key=$1
    local value=$2
    if ! [ -f "$value" ]; then
        error "$key" "$value is not a file"
    fi
}

function directory() {
    local key=$1
    local value=$2
    if ! [ -d "$value" ]; then
        error "$key" "$value is not a directory"
    fi
}

function readable() {
    local key=$1
    local value=$2
    if ! [ -r "$value" ]; then
        error "$key" "$value is not readable"
    fi
}

function writable() {
    local key=$1
    local value=$2
    if ! [ -w "$value" ]; then
        error "$key" "$value is not writable"
    fi
}

function executable() {
    local key=$1
    local value=$2
    if ! [ -x "$value" ]; then
        error "$key" "$value is not executable"
    fi
}

function is_command() {
    local key=$1
    local value=$2
    if ! command -v "$value" >/dev/null; then
        error "$key" "command $value not found"
    fi
}

function readable_file() {
    local key=$1
    local value=$2
    readable "$key" "$value"
    file "$key" "$value"
}

function get_length() {
    echo "${#1}"
}

function length() {
    local key=$1
    local value=$2
    local length=$3
    local actual
    actual=$(get_length "$value")
    if ! [ "$actual" -eq "$length" ]; then
        error "$key" "$value is not $length characters long"
    fi
}

function min_length() {
    local key=$1
    local value=$2
    local length=$3
    local actual
    actual=$(get_length "$value")
    if [ "$actual" -lt "$length" ]; then
        error "$key" "$value is less than $length characters long"
    fi
}

function max_length() {
    local key=$1
    local value=$2
    local length=$3
    local actual
    actual=$(get_length "$value")
    if [ "$actual" -gt "$length" ]; then
        error "$key" "$value is more than $length characters long"
    fi
}

function has_value() {
    local key=$1
    local value=$2
    if [ ! "$value" ]; then
        error "$key" "has no value"
    fi
}

function integer() {
    local key=$1
    local value=$2
    if ! [ "$value" -eq "$value" ]; then
        error "$key" "$value is not an integer"
    fi
}

function integer_min() {
    local key=$1
    local value=$2
    local min=$3
    if ! [ "$value" -ge "$min" ]; then
        error "$key" "$value is less than $min"
    fi
}

function integer_max() {
    local key=$1
    local value=$2
    local max=$3
    if ! [ "$value" -le "$max" ]; then
        error "$key" "$value is greater than $max"
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
