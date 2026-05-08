#!/usr/bin/env bash
set -euo pipefail

# Generates Swift gRPC + Protobuf code from Spec/mobile.proto into
# Sources/ArcaneGRPC/Generated/. Run this whenever the backend's mobile.proto
# changes.
#
# Required tools (any install path works as long as they are on $PATH):
#   - protoc                       (brew install protobuf, or mint install via grpc-swift-protobuf)
#   - protoc-gen-swift             (mint install apple/swift-protobuf, or build from source)
#   - protoc-gen-grpc-swift-2      (mint install grpc/grpc-swift-protobuf — the v2 plugin)
#     The v1 plugin (protoc-gen-grpc-swift) is also accepted as a fallback.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROTO_DIR="${REPO_ROOT}/Spec"
OUT_DIR="${REPO_ROOT}/Sources/ArcaneGRPC/Generated"
ARCANE_REPO="${ARCANE_REPO:-${REPO_ROOT}/../arcane}"
ARCANE_PROTO="${ARCANE_REPO}/backend/pkg/libarcane/edge/proto/mobile/v1/mobile.proto"

# mint binaries land here by default; add to PATH so the script works without
# the user manually exporting it.
if [[ -d "${HOME}/.mint/bin" ]]; then
  PATH="${HOME}/.mint/bin:${PATH}"
fi

if [[ -f "${ARCANE_PROTO}" ]]; then
  echo "Refreshing ${PROTO_DIR}/mobile.proto from ${ARCANE_PROTO}"
  cp "${ARCANE_PROTO}" "${PROTO_DIR}/mobile.proto"
fi

if ! command -v protoc >/dev/null 2>&1; then
  echo "error: protoc is required (brew install protobuf, or install via mint)" >&2
  exit 1
fi
if ! command -v protoc-gen-swift >/dev/null 2>&1; then
  echo "error: protoc-gen-swift is required (mint install apple/swift-protobuf)" >&2
  exit 1
fi

# v2 ships the binary as protoc-gen-grpc-swift-2 so it can coexist with v1.
# Accept either; remap to the canonical "grpc-swift" plugin name when invoking protoc.
GRPC_SWIFT_PLUGIN="$(command -v protoc-gen-grpc-swift-2 || command -v protoc-gen-grpc-swift || true)"
if [[ -z "${GRPC_SWIFT_PLUGIN}" ]]; then
  echo "error: protoc-gen-grpc-swift-2 (v2) or protoc-gen-grpc-swift (v1) is required" >&2
  echo "       install with: mint install grpc/grpc-swift-protobuf" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

protoc \
  --plugin="protoc-gen-grpc-swift=${GRPC_SWIFT_PLUGIN}" \
  --proto_path="${PROTO_DIR}" \
  --swift_out="${OUT_DIR}" \
  --swift_opt=Visibility=Public \
  --grpc-swift_out="${OUT_DIR}" \
  --grpc-swift_opt=Visibility=Public \
  "${PROTO_DIR}/mobile.proto"

echo "Generated Swift gRPC sources in ${OUT_DIR}"
