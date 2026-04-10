# CI Contract

## Local Automation Interface

The canonical local CI entrypoints are:

- `just lint`
- `just test`
- `just build`
- `just security`
- `just ci`

A compatibility Make shim forwards directly to the same commands:

- `make lint`
- `make test`
- `make build`
- `make security`
- `make ci`

## Required GitHub Check Names

Configure branch protection/rulesets to require these status checks:

- `lint`
- `test`
- `build`
- `analyze (swift)`
- `dependency-review`
- `secret-scanning`

Notes:

- `secret-scanning` is provided by GitHub Advanced Security policy, not a custom workflow.
- The helper script `scripts/apply-branch-protection.sh` applies this check list to a target branch.
