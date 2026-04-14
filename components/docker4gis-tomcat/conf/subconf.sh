#!/bin/bash

conf=$1

pushd "$(dirname "$conf")" || exit 1
"$conf"
popd || exit 1
