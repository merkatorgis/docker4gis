#!/bin/bash

# Any output is available on the docker host, at:
# {DOCKER_BINDS_DIR}/runner

# You may write files to share in the /fileport directory,
# which is available on the host as:
# {DOCKER_BINDS_DIR}/runner

# First argument is the process id, which is helpful in log output, eg:
# echo "${ID} success"
ID="${1}"

# The email content is at STDIN
# To get rid of CRLF's, and base64 decode the email, this works:

# EMAIL=$(mktemp)
# tr -d '\r' <&0 > "$EMAIL"

# if grep "base64" "$EMAIL"; then
#         cd $(mktemp -d)
#         csplit "$EMAIL" /^$/
#         openssl enc -base64 -d -in xx01 -out ./out
#         cat xx00 > "$EMAIL"
#         cat ./out >> "$EMAIL"
#         rm -rf "$PWD"
# fi

# CLEAR=$(mktemp)
# tr '\n' '|' < "$EMAIL" | sed 's/=|//g' | sed 's/|/\n/g' > "$CLEAR"
# tr -d '\r' < "$CLEAR" > "$EMAIL"
# rm "$CLEAR"

# # Do things with the ${EMAIL} file

# rm "$EMAIL"

