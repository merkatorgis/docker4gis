# load ~/.bats/helper.bash
#
# function setup_file() {
#     helper
# }

# Start any bats file with the (uncommented) lines above ↑.

# Load the bats libs for which we included the sources here, in the absence of a
# proper npm package for them. See https://www.shellcheck.net/wiki/SC2044 for
# the loop over `find`.
while IFS= read -r -d '' lib; do
    load "$lib"/load.bash
done < <(find "$DOCKER_BASE/.plugins/bats" -type d -name "bats-*-*" -print0)

helper() {
    # Set the CMD variable to "the command under test", assuming the test file
    # is named $CMD.bats, e.g. the-command.sh.bats -> the-command.sh (in the
    # same directory).
    CMD="$BATS_TEST_DIRNAME/$(basename "$BATS_TEST_FILENAME" .bats)"
    CMD=$(realpath "$CMD")
    export CMD
}
