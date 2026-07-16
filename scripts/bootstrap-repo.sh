#!/usr/bin/env bash
# Bootstrap one thebigtechplus repository (labels, CODEOWNERS, teams, merge + branch rules).
# Does NOT apply to all repos — pass the repo name each time.
#
# Usage:
#   ./scripts/bootstrap-repo.sh <repo-name>
#   ./scripts/bootstrap-repo.sh <repo-name> --create
#
# Requires: GitHub CLI (gh), authenticated — required for all BigTech+ developers
# Platforms: macOS, Linux, Windows (Git Bash or WSL)
#
# Prefer from anywhere:
#   gh extension install thebigtechplus/gh-bootstrap-repo
#   gh bootstrap-repo <repo-name> [--create]
#
# Or:
#   curl -fsSL https://raw.githubusercontent.com/thebigtechplus/.github/main/scripts/bootstrap-repo.sh | bash -s -- <repo-name> [--create]

set -euo pipefail

ORG="thebigtechplus"
DEVELOPERS_TEAM="developers"
ADMINS_TEAM="admins"
CODEOWNERS_BODY='* @thebigtechplus/developers
'

usage() {
  cat <<'EOF'
Usage: bootstrap-repo.sh <repo-name> [--create]

  <repo-name>   Repository name only (not owner/name). Example: api
  --create      Create a private repo under thebigtechplus if it does not exist

This configures ONE repository. It does not cascade to other or future repos.
To bootstrap several repos:

  ./scripts/bootstrap-repo.sh api --create
  ./scripts/bootstrap-repo.sh web --create

Windows: run from Git Bash or WSL (or use scripts/bootstrap-repo.ps1).
EOF
}

b64_encode() {
  # Portable: avoid GNU/BSD base64 flag differences
  if command -v openssl >/dev/null 2>&1; then
    printf '%s' "$1" | openssl base64 | tr -d '\n\r'
  elif command -v base64 >/dev/null 2>&1; then
    printf '%s' "$1" | base64 | tr -d '\n\r'
  else
    echo "error: need openssl or base64" >&2
    exit 1
  fi
}

die() {
  echo "error: $*" >&2
  exit 1
}

need_gh() {
  command -v gh >/dev/null 2>&1 || die "gh CLI not found. Install: https://cli.github.com/"
  gh auth status >/dev/null 2>&1 || die "gh is not authenticated. Run: gh auth login"
}

REPO=""
CREATE=0

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    --create)
      CREATE=1
      ;;
    -*)
      die "unknown option: $arg"
      ;;
    *)
      if [[ -n "$REPO" ]]; then
        die "unexpected argument: $arg"
      fi
      REPO="$arg"
      ;;
  esac
done

[[ -n "$REPO" ]] || { usage >&2; exit 1; }
[[ "$REPO" != */* ]] || die "pass the repo name only (got '$REPO'). Example: api"

need_gh

FULL="$ORG/$REPO"

if gh repo view "$FULL" >/dev/null 2>&1; then
  echo "→ repository exists: $FULL"
elif [[ "$CREATE" -eq 1 ]]; then
  echo "→ creating private repository: $FULL"
  gh repo create "$FULL" --private --default-branch main --confirm
else
  die "repository $FULL not found. Re-run with --create, or create it first."
fi

echo "→ ensuring labels"
gh label create bug --repo "$FULL" --color d73a4a --description "Something isn't working" --force >/dev/null
gh label create enhancement --repo "$FULL" --color a2eeef --description "New feature or request" --force >/dev/null
gh label create dependencies --repo "$FULL" --color 0366d6 --description "Dependency updates" --force >/dev/null
gh label create github-actions --repo "$FULL" --color 2088FF --description "GitHub Actions related" --force >/dev/null

echo "→ ensuring CODEOWNERS"
CONTENT_B64="$(b64_encode "$CODEOWNERS_BODY")"
SHA="$(gh api "repos/$FULL/contents/CODEOWNERS" --jq .sha 2>/dev/null || true)"
if [[ -n "$SHA" ]]; then
  gh api -X PUT "repos/$FULL/contents/CODEOWNERS" \
    -f message="chore: update CODEOWNERS" \
    -f content="$CONTENT_B64" \
    -f sha="$SHA" >/dev/null
else
  gh api -X PUT "repos/$FULL/contents/CODEOWNERS" \
    -f message="chore: add CODEOWNERS" \
    -f content="$CONTENT_B64" >/dev/null
fi

echo "→ team access (developers: write, admins: admin)"
gh api -X PUT "orgs/$ORG/teams/$DEVELOPERS_TEAM/repos/$FULL" --input - <<<'{"permission":"push"}' >/dev/null
gh api -X PUT "orgs/$ORG/teams/$ADMINS_TEAM/repos/$FULL" --input - <<<'{"permission":"admin"}' >/dev/null

echo "→ merge settings (squash only)"
MERGE_JSON="$(mktemp "${TMPDIR:-/tmp}/btp-merge.XXXXXX")"
cat >"$MERGE_JSON" <<'EOF'
{
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": false,
  "delete_branch_on_merge": true,
  "has_wiki": false
}
EOF
gh api -X PATCH "repos/$FULL" --input "$MERGE_JSON" >/dev/null
rm -f "$MERGE_JSON"

echo "→ branch protection on main"
PROTECT_JSON="$(mktemp "${TMPDIR:-/tmp}/btp-protect.XXXXXX")"
cat >"$PROTECT_JSON" <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
EOF
set +e
PROTECT_OUT="$(gh api -X PUT "repos/$FULL/branches/main/protection" --input "$PROTECT_JSON" 2>&1)"
PROTECT_STATUS=$?
set -e
rm -f "$PROTECT_JSON"
if [[ "$PROTECT_STATUS" -ne 0 ]]; then
  echo "warning: could not fully set branch protection (common on GitHub Free private repos)."
  echo "         Apply what you can under Settings → Branches for $FULL."
  echo "$PROTECT_OUT" | sed 's/^/         /' >&2
else
  echo "→ branch protection applied"
fi

echo
echo "Done: $FULL"
echo "Inherited from org .github (if this repo has no local ISSUE_TEMPLATE): issue/PR templates + community docs."
echo "Smoke-check: open New issue on https://github.com/$FULL/issues/new/choose"
