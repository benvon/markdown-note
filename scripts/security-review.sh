#!/usr/bin/env bash
set -euo pipefail

./scripts/secret-scan.sh

# Validate dependency graph generation as a local dependency-review preflight.
swift package show-dependencies --format json >/dev/null

echo "Security preflight passed"
echo "GitHub-required security checks are enforced in CI via CodeQL + Dependency Review + GHAS secret scanning policy."
