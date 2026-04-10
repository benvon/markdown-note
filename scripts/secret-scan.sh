#!/usr/bin/env bash
set -euo pipefail

if ! command -v rg >/dev/null 2>&1; then
  echo "ripgrep (rg) is required for secret scanning"
  exit 1
fi

readonly EXCLUDE_GLOBS=(
  '!.git/**'
  '!.build/**'
  '!DerivedData/**'
  '!dist/**'
  '!*.png'
  '!*.jpg'
  '!*.jpeg'
  '!*.gif'
)

readonly SECRET_PATTERNS=(
  'AKIA[0-9A-Z]{16}'
  'ghp_[A-Za-z0-9]{36}'
  'ghs_[A-Za-z0-9]{36}'
  'xox[baprs]-[A-Za-z0-9-]{10,48}'
  '-----BEGIN (RSA|EC|OPENSSH|DSA|PRIVATE) PRIVATE KEY-----'
)

rg_args=(--hidden -n)
for glob in "${EXCLUDE_GLOBS[@]}"; do
  rg_args+=(--glob "${glob}")
done
for pattern in "${SECRET_PATTERNS[@]}"; do
  rg_args+=(-e "${pattern}")
done

matches=$(rg "${rg_args[@]}" . || true)

if [[ -n "${matches}" ]]; then
  echo "Potential secrets detected:"
  echo "${matches}"
  exit 1
fi

echo "Secret scan passed"
