# Markdown Note

A native macOS Markdown editor focused on low-distraction note taking.

## Editing Model

- The active markdown block under the cursor shows raw markdown source.
- Non-active blocks are rendered into readable text.
- Fixed single-row line layout + disabled soft wrapping avoids vertical jumpiness while moving the caret.
- Tables and other complex area-style markdown are intentionally deferred in v1.

## Project Layout

- `Sources/MarkdownNoteApp`: AppKit document app shell (`NSDocument`, windows, editor coordinator).
- `Sources/MarkdownNoteCore`: Block resolution and markdown rendering logic.
- `Tests/MarkdownNoteCoreTests`: Core unit tests.
- `.github/workflows`: CI + security workflows.

## Local Development

Run the app:

```bash
swift run MarkdownNoteApp
```

Or build and run the generated executable directly:

```bash
just build
BIN_DIR=$(swift build --show-bin-path)
"$BIN_DIR/MarkdownNoteApp"
```

Open editor settings with `Markdown Note` > `Settings…` (or `Cmd+,`) to configure:

- Source typeface
- Rendered typeface
- Font size
- Text/background/secondary colors

Build distributable release artifacts (`.app`, `.zip`, `.pkg`, `.dmg`):

```bash
just package
```

Artifacts are emitted to `dist/`.

Run local CI tasks (primary interface):

```bash
just lint
just test
just build
just security
just ci
```

Makefile shim commands are also available (`make ci`, etc.) and forward to `just`.

## GitHub CI/Security

- CI workflow: lint, test, build on macOS.
- Security workflows: CodeQL and Dependency Review.
- GHAS secret scanning is expected as a required branch protection gate.

See [docs/ci-contract.md](docs/ci-contract.md) for required check names.

## Continuous Delivery

- CD workflow: [`.github/workflows/cd.yml`](.github/workflows/cd.yml)
- Triggers:
  - Manual run (`workflow_dispatch`)
  - Tag push (`v*`) for release publishing
- Produced artifacts:
  - `dist/MarkdownNote-<version>.zip`
  - `dist/MarkdownNote-<version>.pkg`
  - `dist/MarkdownNote-<version>.dmg`

Optional signing environment variables for local packaging:

- `SIGNING_IDENTITY` for app bundle `codesign`
- `PKG_SIGNING_IDENTITY` for installer package signing
