#!/bin/bash

src_dir="$(pwd)/../../api"

"${DOCKER_BASE}/ant/build.sh" "${src_dir}"
