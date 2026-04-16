# Testing docker4gis

Docker4gis supports both component-level unit tests and application-level
integration tests.

## Unit tests

To run a component's unit tests, use:

```
dg test [COMPONENT]
```

This can do zero or more of the following:

- Run any `test.sh` commands in the component directory.
- Run any [BATS](https://github.com/bats-core/bats-core) tests in the component
  directory.

## Integration tests

To run the application's integration tests, use:

```
dg test
```

This uses the same test mechanisms as component testing, but looks in the
application-level test location rather than component directories.

## Build and run

When you run:

```
dg build [COMPONENT]
```

the relevant component tests are run before the image is built. If a test
fails, the build is cancelled.

To build a component and run the application with that new image immediately,
use:

```
dg br [COMPONENT]
```

## Bash Automated Testing System

Running BATS tests is integrated in docker4gis, but it depends on a local BATS
installation. The test runner will try to install it for you through
[npm](https://www.npmjs.com/package/bats), when available.

### Helper

In a `.bats` test file, load the shared helper like this:

```bash
#!/usr/bin/env bats
load "$DOCKER_BASE"/test_helper/load.bash
```

This loads the
[bats-assert](https://github.com/bats-core/bats-assert) and
[bats-file](https://github.com/bats-core/bats-file) modules.

It also exposes a `$CMD` variable containing the command under test, assuming
the `.bats` file matches the command file name and location, with only the extra
`.bats` suffix added.

### Plugin

In shell commands under test, include the BATS plugin file like this:

```bash
#!/bin/bash
# shellcheck source=/dev/null
source ~/.bats.bash
```

### Subroutines

The plugin provides an `@sub` function to break shell scripts into smaller,
testable subroutines:

```bash
#!/bin/bash
ID=$1

LOADER_ROOT_DIR=${LOADER_ROOT_DIR:-"/fileport/$DOCKER_USER"}

# shellcheck source=/dev/null
source ~/.bats.bash

@sub 1 check_running "$(basename "$0")"

@sub 2 dir "$LOADER_ROOT_DIR"
dir="${output:?}"

klicmeldnr=$(ls "$dir"/extracted)
echo "$ID $klicmeldnr converting in $dir ..."
@sub 3 run_loader "$dir"
echo "$ID $klicmeldnr converting in $dir finished with status $output"
```

Parameters to `@sub` are:

1. The nonzero exit code your script should return if the subroutine fails.
1. The basename of a script file named `sub/{basename}.sh` relative to the
   current script's location.
1. Any parameters to pass to the subcommand.

Any output of a successful subroutine is available in the `$output` variable.
The actual subcommand exit code is available in `$status`.

If the main script needs to continue after a failing subroutine, use `@subvive`
instead of `@sub`:

```bash
if @subvive 1 daytime; then
    timestring=${output:?}
    daytime=true
fi
```

### Validations

In subroutine scripts, include the plugin as well, and use its assertion
functions to validate input parameters:

```bash
#!/bin/bash
# shellcheck source=/dev/null
source ~/.bats.bash

assert_readable_file file "$file"
assert_integer_min MAX_BYTES "$MAX_BYTES" 0
assert_integer_min_max_length MIN_TIME_H "$MIN_TIME_H" 00 23 2
assert_integer_min_max_length MIN_TIME_M "$MIN_TIME_M" 00 59 2
assert_integer_min_max_length MAX_TIME_H "$MAX_TIME_H" 00 23 2
assert_integer_min_max_length MAX_TIME_M "$MAX_TIME_M" 00 59 2
assert_integer_min_max_length cur_time "$cur_time" 0000 2359 4
```

Any violated assertion makes the script fail with error 22 (`EINVAL`) using the
given name and value in the error message. From a `.bats` test script, use
`assert_failure 22` to check for expected input validation failures:

```bash
#!/usr/bin/env bats
load "$DOCKER_BASE"/test_helper/load.bash

@test 'string MAX_BYTES' {
    export MAX_BYTES=aa
    run "$CMD" "$file"
    assert_failure 22
}

@test 'negative MIN_TIME_H' {
    export MIN_TIME_H=-1
    run "$CMD" "$file"
    assert_failure 22
}
```