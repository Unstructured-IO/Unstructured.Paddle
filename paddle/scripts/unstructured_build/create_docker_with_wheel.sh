#!/bin/bash

set -euo pipefail
DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-quay.io/unstructured-io/paddle}"
PIP_VERSION="${PIP_VERSION:-22.2.1}"
DOCKER_IMAGE="${DOCKER_IMAGE:-paddle}"
DOCKER_FILE="paddle/scripts/unstructured_build/manylinux_amd.dockerfile"

DOCKER_BUILD_CMD=(docker buildx build --load \
  --build-arg PIP_VERSION="$PIP_VERSION" \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --platform linux/amd64 \
  --progress plain \
  --cpuset-cpus=2 --memory=4g --memory-swap=4g \
  --ulimit nofile=8192 --ulimit fsize=10000000 \
  --cache-from "$DOCKER_REPOSITORY":amd \
  -t "$DOCKER_IMAGE" -f "./$DOCKER_FILE" .)

# only build for specific platform if DOCKER_BUILD_PLATFORM is set
if [ -n "${DOCKER_BUILD_PLATFORM:-}" ]; then
  DOCKER_BUILD_CMD+=("--platform=$DOCKER_BUILD_PLATFORM")
fi

DOCKER_BUILDKIT=1 "${DOCKER_BUILD_CMD[@]}"
