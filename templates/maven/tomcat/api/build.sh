#!/bin/bash

src_dir="$(pwd)/../../app_name"

"${DOCKER_BASE}/maven/tomcat/build.sh" "${src_dir}"
