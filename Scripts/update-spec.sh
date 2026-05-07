#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARCANE_REPO="${ARCANE_REPO:-${REPO_ROOT}/../arcane}"
OUT="${REPO_ROOT}/Spec/openapi.json"
GENERATOR="${GENERATOR:-swift-openapi-generator}"
TMP_YAML="$(mktemp)"

cleanup() {
  rm -f "${TMP_YAML}"
}
trap cleanup EXIT

if ! command -v yq >/dev/null 2>&1; then
  echo "error: yq is required to convert downgraded OpenAPI YAML to JSON" >&2
  exit 1
fi

if ! command -v "${GENERATOR}" >/dev/null 2>&1; then
  echo "error: ${GENERATOR} is required to regenerate Sources/ArcaneAPI" >&2
  echo "Install it with: mint install apple/swift-openapi-generator" >&2
  echo "Or run with GENERATOR=/path/to/swift-openapi-generator ${0}" >&2
  exit 1
fi

(
  cd "${ARCANE_REPO}"
  go run ./backend/cmd openapi --format yaml --downgrade -o "${TMP_YAML}"
)

jq_filter='
  def sanitize_component_name: gsub("[^A-Za-z0-9._-]"; "");
  def walk(f):
    . as $in
    | if type == "object" then
        reduce keys_unsorted[] as $key ({}; . + {($key): ($in[$key] | walk(f))}) | f
      elif type == "array" then
        map(walk(f)) | f
      else
        f
      end;
  .components.schemas = (.components.schemas | with_entries(.key |= sanitize_component_name))
  | walk(
      if type == "object" and has("$ref") and (."$ref" | type == "string") then
        ."$ref" |= sub("#/components/schemas/(?<name>.*)$"; "#/components/schemas/" + (.name | sanitize_component_name))
      else
        .
      end
    )
'

yq -o=json '.' "${TMP_YAML}" | jq "${jq_filter}" > "${OUT}"
jq -e '.openapi == "3.0.3"' "${OUT}" >/dev/null
echo "OpenAPI spec written to ${OUT}"

"${GENERATOR}" generate "${OUT}" \
  --config "${REPO_ROOT}/Generator/openapi-generator-config.yaml" \
  --output-directory "${REPO_ROOT}/Sources/ArcaneAPI"
echo "Generated ArcaneAPI Swift sources in ${REPO_ROOT}/Sources/ArcaneAPI"
