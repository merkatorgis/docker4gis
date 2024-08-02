# Start any bats file with:
# #!/usr/bin/env bats
# load ~/.bats/helper.bash

base=$(basename "$BATS_TEST_FILENAME" .bats)
cmd="$BATS_TEST_DIRNAME"/"$base"

git -C "$DOCKER_BASE/.." submodule init
git -C "$DOCKER_BASE/.." submodule update

load "$DOCKER_BASE"/test_helper/bats-support/load.bash
load "$DOCKER_BASE"/test_helper/bats-assert/load.bash
load "$DOCKER_BASE"/test_helper/bats-file/load.bash
