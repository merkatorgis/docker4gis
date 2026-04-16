#!/bin/bash

# From the Dockerfile, extensions ($STABLE_EXTENSIONS and $COMMUNITY_EXTENSIONS)
# are downloaded into (and installed from) $ADDITIONAL_LIBS_DIR. Afterwards,
# this script is run to save the downloaded extensions into the repo's sources,
# so that on a subsequent build, the extensions do not have to be downloaded
# again.

# Save the extensions to /save_additional_libs
for EXTENSION in $(echo "${STABLE_EXTENSIONS},${COMMUNITY_EXTENSIONS}" | tr ',' ' '); do
  ADDITIONAL_LIB=${ADDITIONAL_LIBS_DIR}geoserver-${GEOSERVER_VERSION}-${EXTENSION}-plugin.zip
  [ -e "$ADDITIONAL_LIB" ] && cp "$ADDITIONAL_LIB" /save_additional_libs
done
