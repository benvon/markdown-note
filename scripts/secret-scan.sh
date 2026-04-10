#!/usr/bin/env bash
set -euo pipefail

if ! command -v rg >/dev/null 2>&1; then
  echo "ripgrep (rg) is required for secret scanning"
  exit 1
fi

matches=$(rg \
  --hidden \
  --glob '!.git/*' \
  --glob '!*.png' \
  --glob '!*.jpg' \
  --glob '!*.jpeg' \
  --glob '!*.gif' \
  -n \
  -e 'AKIA[0-9A-Z]{16}' \
  -e 'ghp_[A-Za-z0-9]{36}' \
  -e 'ghs_[A-Za-z0-9]{36}' \
  -e 'xox[baprs]-[A-Za-z0-9-]{10,48}' \
  -e '-----BEGIN (RSA|EC|OPENSSH|DSA|PRIVATE) PRIVATE KEY-----' \
  . || true)

if [[ -n "${matches}" ]]; then
  echo "Potential secrets detected:"
  echo "${matches}"
  exit 1
fi

echo "Secret scan passed"
