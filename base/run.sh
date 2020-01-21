#!/bin/bash

DOCKER_BASE="${DOCKER_BASE}"

tag="${1:-latest}"

echo '' | "${DOCKER_BASE}/package/run.sh" "${tag}"
