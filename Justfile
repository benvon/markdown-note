set shell := ["bash", "-euo", "pipefail", "-c"]

default: ci

lint:
    swift format lint --recursive Sources Tests Package.swift

test:
    swift test

build:
    swift build --target MarkdownNoteApp

package:
    ./scripts/release/build-release-artifacts.sh

security:
    ./scripts/security-review.sh

ci: lint test build security
