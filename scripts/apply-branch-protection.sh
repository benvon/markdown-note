#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <owner/repo> [branch]"
  exit 1
fi

repo="$1"
branch="${2:-main}"

# Requires authenticated gh CLI with admin rights on the repository.
gh api --method PUT "repos/${repo}/branches/${branch}/protection" \
  --header "Accept: application/vnd.github+json" \
  --input - <<JSON
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "lint",
      "test",
      "build",
      "analyze (swift)",
      "dependency-review",
      "secret-scanning"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
JSON

echo "Branch protection updated for ${repo}:${branch}"
