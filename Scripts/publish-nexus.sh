#!/usr/bin/env bash
set -euo pipefail

REGISTRY_URL="${REGISTRY_URL:-https://pkgs.getarcane.app/repository/swift/}"
PACKAGE_ID="${PACKAGE_ID:-getarcaneapp.libarcane-swift}"
VERSION="${1:-${VERSION:-}}"

if [[ -z "${VERSION}" ]]; then
  echo "usage: VERSION=1.0.0 ${0}" >&2
  echo "   or: ${0} 1.0.0" >&2
  exit 1
fi

if [[ "${VERSION}" != v* ]]; then
  TAG="v${VERSION}"
else
  TAG="${VERSION}"
  VERSION="${VERSION#v}"
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: publish must run from a git checkout" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: working tree is dirty; commit generated sources before publishing" >&2
  exit 1
fi

swift build

if ! git rev-parse "${TAG}" >/dev/null 2>&1; then
  git tag -a "${TAG}" -m "Arcane Swift ${VERSION}"
fi

swift package-registry publish "${PACKAGE_ID}" "${VERSION}" \
  --url "${REGISTRY_URL}"
