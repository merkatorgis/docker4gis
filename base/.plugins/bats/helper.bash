# Start any bats file with:
#
# #!/usr/bin/env bats
# load ~/.bats/helper.bash

# https://www.shellcheck.net/wiki/SC2044
while IFS= read -r -d '' lib; do
    lib=$(basename "$lib")
    # cf. https://github.com/drevops/bats-helpers?tab=readme-ov-file#usage
    bats_load_library "$lib"
done < <(find "$BATS_LIB_PATH" -type d -name "bats-*-*" -print0)

base=$(basename "$BATS_TEST_FILENAME" .bats)
cmd="$BATS_TEST_DIRNAME"/"$base"
