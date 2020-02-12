#!/bin/bash

# To specify any directory to copy to the image & serve:
# build_dir="$(pwd)/../../app"
# If left empty, dynamic content is served from "${DOCKER_BINDS_DIR}/fileport${DOCKER_USER}"

"${DOCKER_BASE}/serve/build.sh" "${build_dir}" 
