#!/bin/bash

# Any output is available on the docker host, at:
# {DOCKER_BINDS_DIR}/runner

# You may write files to share in the /fileport directory,
# which is available on the host as:
# {DOCKER_BINDS_DIR}/fileport

# First argument is the process id, which is helpful in log output
id="${1}"
param1="${2}"
param2="${3}"

# The email content is at STDIN
cd $(mktemp -d)
cat <&0 > email

# ripmime puts the message text in textfile0,
# and any text attachments in textfile1...texfilen
ripmime -i email -d .
files="textfile*"
for f in $files
do
    whatyouwant f
done

rm -rf $(pwd)
echo "${id} OK"
