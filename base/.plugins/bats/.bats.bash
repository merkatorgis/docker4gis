# Sub-command runner and input validation functions for testable bash commands.
#
# Include in a bash command as follows:
#
# # shellcheck source=/dev/null
# source ~/.bats.bash

function @sub() {
    _sub 'false' "$@"
}

function @subvive() {
    _sub 'true' "$@"
}

function _sub() {
    local survive=$1
    local err=$2
    local cmd=$3
    shift 3
    cmd="$(dirname "$0")/sub/$cmd.sh"
    assert_integer_min err "$err" 1
    assert_integer_max err "$err" 255
    assert_command "$cmd"

    output=$("$cmd" "$@")
    status=$?
    if [ "$status" -eq 0 ]; then
        return 0
    else
        if [ "$survive" != 'true' ]; then
            echo "$ID $err $status $output"
            exit "$err"
        else
            return "$err"
        fi
    fi
}

function error() {
    local key=$1
    local value=$2
    echo "ERR_INVALID_INPUT" "- $key:" "$value"
    exit 22 # EINVAL
}

function assert_exists() {
    local key=$1
    local value=$2
    if ! [ -e "$value" ]; then
        error "$key" "$value not found"
    fi
}

function assert_file() {
    local key=$1
    local value=$2
    if ! [ -f "$value" ]; then
        error "$key" "$value is not a file"
    fi
}

function assert_directory() {
    local key=$1
    local value=$2
    if ! [ -d "$value" ]; then
        error "$key" "$value is not a directory"
    fi
}

function assert_readable() {
    local key=$1
    local value=$2
    if ! [ -r "$value" ]; then
        error "$key" "$value is not readable"
    fi
}

function assert_writable() {
    local key=$1
    local value=$2
    if ! [ -w "$value" ]; then
        error "$key" "$value is not writable"
    fi
}

function assert_executable() {
    local key=$1
    local value=$2
    if ! [ -x "$value" ]; then
        error "$key" "$value is not executable"
    fi
}

function assert_command() {
    local cmd=$1
    local hint=$2
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error "command $cmd not found. $hint"
    fi
}

function assert_readable_file() {
    local key=$1
    local value=$2
    assert_readable "$key" "$value"
    assert_file "$key" "$value"
}

function length() {
    echo "${#1}"
}

function assert_length() {
    local key=$1
    local value=$2
    local want=$3
    local is
    is=$(length "$value")
    if ! [ "$is" -eq "$want" ]; then
        error "$key" "$value is not $want characters long"
    fi
}

function assert_min_length() {
    local key=$1
    local value=$2
    local want=$3
    local is
    is=$(length "$value")
    if [ "$is" -lt "$want" ]; then
        error "$key" "$value is less than $want characters long"
    fi
}

function assert_max_length() {
    local key=$1
    local value=$2
    local want=$3
    local is
    is=$(length "$value")
    if [ "$is" -gt "$want" ]; then
        error "$key" "$value is more than $want characters long"
    fi
}

function assert_has_value() {
    local key=$1
    local value=$2
    if [ ! "$value" ]; then
        error "$key" "has no value"
    fi
}

function assert_not() {
    local key=$1
    local value=$2
    local not=$3
    if [ "$value" = "$not" ]; then
        error "$key" "$value must not be $not"
    fi
}

function assert_integer() {
    local key=$1
    local value=$2
    if ! [ "$value" -eq "$value" ]; then
        error "$key" "$value is not an integer"
    fi
}

function assert_integer_not() {
    local key=$1
    local value=$2
    local not=$3
    assert_integer "$key" "$value"
    assert_not "$key" "$value" "$not"
}

function assert_integer_min() {
    local key=$1
    local value=$2
    local min=$3
    if ! [ "$value" -ge "$min" ]; then
        error "$key" "$value is less than $min"
    fi
}

function assert_integer_max() {
    local key=$1
    local value=$2
    local max=$3
    if ! [ "$value" -le "$max" ]; then
        error "$key" "$value is greater than $max"
    fi
}

function assert_integer_min_max() {
    local key=$1
    local value=$2
    local min=$3
    local max=$4
    assert_integer_min "$key" "$value" "$min"
    assert_integer_max "$key" "$value" "$max"
}

function assert_integer_min_max_length() {
    local key=$1
    local value=$2
    local min=$3
    local max=$4
    local length=$5
    assert_integer_min_max "$key" "$value" "$min" "$max"
    assert_length "$key" "$value" "$length"
}
