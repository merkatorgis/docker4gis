#!/bin/bash

# Any output is available on the docker host, at:
# {DOCKER_BINDS_DIR}/runner/{DOCKER_USER}/postfix.

# You may write files to the host in the /fileport directory, which maps to:
# {DOCKER_BINDS_DIR}/fileport/{DOCKER_USER}/postfix, or in the /fileport/root
# directory, leading to {DOCKER_BINDS_DIR}/fileport/{DOCKER_USER} (where some
# sibling containers may read what you write).

# The email content is at STDIN
cd "$(mktemp -d)" || exit 1
cat <&0 >email

# ripmime puts the message text in textfile0,
# and any text attachments in textfile1...texfilen
ripmime -i email -d .
files="textfile*"
for f in $files; do
    whatyouwant "$f"
done

rm -rf "$(pwd)"

# Prepend output with the parent process's id, to help identifying which log
# file content comes from which process.
echo "$PPID OK"
