# Shared fixtures for docker4gis CLI tests.

DG="$(realpath "$BATS_TEST_DIRNAME/../docker4gis")"
export DG

# Prepend a failing docker stub to PATH so commands that would otherwise
# block on interactive base-image selection exit immediately instead.
# Requires WORKDIR to be set before calling.
_setup_mock_docker() {
    mkdir -p "$WORKDIR/mock-bin"
    printf '#!/bin/bash\nexit 1\n' > "$WORKDIR/mock-bin/docker"
    chmod +x "$WORKDIR/mock-bin/docker"
    export PATH="$WORKDIR/mock-bin:$PATH"
}

# Create a minimal fake docker4gis component directory.
# Args: [dir] — defaults to $WORKDIR.
_make_fake_component() {
    local dir="${1:-$WORKDIR}"
    printf 'DOCKER4GIS_VERSION=0.0.1\nDOCKER_REPO=mycomp\n' > "$dir/.env"
    printf '{"version":"0.0.0"}\n' > "$dir/package.json"
}

# Create a minimal fake docker4gis monorepo root with a components/ directory.
# Args: root
_make_fake_monorepo() {
    local root="$1"
    mkdir -p "$root/components"
    printf 'DOCKER4GIS_ROOT=true\nDOCKER_USER=testapp\nDOCKER_REGISTRY=docker.io\nDOCKER4GIS_VERSION=0.0.1\n' > "$root/.env"
    printf '{"version":"0.0.0"}\n' > "$root/package.json"
}
