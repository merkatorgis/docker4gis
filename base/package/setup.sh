#!/bin/bash

# shellcheck disable=SC2016
echo '#!/bin/bash

tag=$1
'
cat "$(dirname "$0")"/setup_pipeline.sh
