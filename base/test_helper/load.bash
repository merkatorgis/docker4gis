# Start any bats file with:
# #!/usr/bin/env bats
# load "$DOCKER_BASE"/test_helper/load.bash

base=$(basename "$BATS_TEST_FILENAME" .bats)
cmd="$BATS_TEST_DIRNAME"/"$base"

load "$DOCKER_BASE"/test_helper/bats-support/load.bash
load "$DOCKER_BASE"/test_helper/bats-assert/load.bash
load "$DOCKER_BASE"/test_helper/bats-file/load.bash
