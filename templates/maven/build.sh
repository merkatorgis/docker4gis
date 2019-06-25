#!/bin/bash

src_dir="$(pwd)/../../app_name"

"${DOCKER_BASE}/maven/build.sh" "${src_dir}"
