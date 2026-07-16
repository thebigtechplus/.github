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
#   gh bootstrap-repo <repo-name> [--create] [--public]
#
# Or:
#   curl -fsSL https://raw.githubusercontent.com/thebigtechplus/.github/main/scripts/bootstrap-repo.sh | bash -s -- <repo-name> [--create]

set -euo pipefail

ORG="thebigtechplus"
TEMPLATE_REPO="thebigtechplus/.github"
DEVELOPERS_TEAM="developers"
ADMINS_TEAM="admins"
CODEOWNERS_BODY='* @thebigtechplus/admins
'

b64_decode() {
  if command -v openssl >/dev/null 2>&1; then
    openssl base64 -d -A 2>/dev/null || openssl base64 -d
  else
    base64 --decode 2>/dev/null || base64 -d
  fi
}

fetch_template() {
  local name="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "$script_dir/templates/$name" ]]; then
    cat "$script_dir/templates/$name"
    return
  fi
  gh api "repos/${TEMPLATE_REPO}/contents/scripts/templates/${name}" --jq .content | tr -d '\n' | b64_decode
}

ensure_repo_file_if_missing() {
  local path="$1"
  local content="$2"
  local message="$3"

  if gh api "repos/$FULL/contents/$path" --jq .sha >/dev/null 2>&1; then
    echo "  skipped ($path exists)"
    return
  fi

  gh api -X PUT "repos/$FULL/contents/$path" \
    -f message="$message" \
    -f content="$(b64_encode "$content")" >/dev/null
  echo "  added $path"
}

seed_repo_templates() {
  local readme_content agents_content claude_content precommit_content markdownlint_content
  readme_content="$(fetch_template README.md)"
  readme_content="${readme_content//\{\{REPO\}\}/$REPO}"
  agents_content="$(fetch_template AGENTS.md)"
  claude_content="$(fetch_template CLAUDE.md)"
  precommit_content="$(fetch_template .pre-commit-config.yaml)"
  markdownlint_content="$(fetch_template .markdownlint.yaml)"

  echo "→ ensuring README.md"
  ensure_repo_file_if_missing "README.md" "$readme_content" "docs: add README from org template"

  echo "→ ensuring AGENTS.md"
  ensure_repo_file_if_missing "AGENTS.md" "$agents_content" "docs: add AGENTS.md from org template"

  echo "→ ensuring CLAUDE.md"
  ensure_repo_file_if_missing "CLAUDE.md" "$claude_content" "docs: add CLAUDE.md from org template"

  echo "→ ensuring .pre-commit-config.yaml"
  ensure_repo_file_if_missing ".pre-commit-config.yaml" "$precommit_content" "chore: add pre-commit config from org template"

  echo "→ ensuring .markdownlint.yaml"
  ensure_repo_file_if_missing ".markdownlint.yaml" "$markdownlint_content" "chore: add markdownlint config from org template"
}

print_pre_commit_guide() {
  cat <<EOF

→ pre-commit: install locally (one-time per clone)
  pip install pre-commit    # or: brew install pre-commit

  pre-commit install        # installs pre-commit + commit-msg hooks (see default_install_hook_types)
  pre-commit run --all-files   # optional: verify the repo now

  Hooks: whitespace, YAML, merge conflicts, large files, private keys, Conventional Commits,
         shellcheck, markdownlint, gitleaks.

  Docs: https://pre-commit.com/

EOF
}

usage() {
  cat <<'EOF'
Usage: bootstrap-repo.sh <repo-name> [--create] [--public]

  <repo-name>   Repository name only (not owner/name). Example: api
  --create      Create the repo under thebigtechplus if it does not exist (private by default)
  --public      With --create, create a public repo instead of private

This configures ONE repository. It does not cascade to other or future repos.
To bootstrap several repos:

  ./scripts/bootstrap-repo.sh api --create
  ./scripts/bootstrap-repo.sh oss-demo --create --public

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
PUBLIC=0

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    --create)
      CREATE=1
      ;;
    --public)
      PUBLIC=1
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
[[ "$PUBLIC" -eq 0 || "$CREATE" -eq 1 ]] || die "--public requires --create"

need_gh

FULL="$ORG/$REPO"

if gh repo view "$FULL" >/dev/null 2>&1; then
  echo "→ repository exists: $FULL"
elif [[ "$CREATE" -eq 1 ]]; then
  if [[ "$PUBLIC" -eq 1 ]]; then
    echo "→ creating public repository: $FULL"
    gh repo create "$FULL" --public
  else
    echo "→ creating private repository: $FULL"
    gh repo create "$FULL" --private
  fi
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

echo "→ team access (developers: write, admins: admin; reviews via CODEOWNERS → admins)"
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

seed_repo_templates

print_pre_commit_guide

print_branch_protection_guide() {
  cat <<EOF

→ branch protection: configure manually in the web UI
  Bootstrap does not set branch protection (GitHub Free private org repos require Team).

  Open: https://github.com/$FULL/settings/rules

  Add a branch ruleset (or classic rule) for branch \`main\` with:

  - Require a pull request before merging
  - Required approvals: 1
  - Require review from Code Owners (after CODEOWNERS is in place)
  - Dismiss stale pull request approvals when new commits are pushed
  - Require conversation resolution before merging
  - Do not allow bypassing the above settings (optional; admins may want bypass on org .github)
  - Restrict force pushes
  - Restrict deletions

  On GitHub Free, these options may be unavailable for private repositories until the
  organization upgrades to GitHub Team, or the repository is public.

  Docs: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches

EOF
}

print_branch_protection_guide

echo "Done: $FULL"
echo "Inherited from org .github (if this repo has no local ISSUE_TEMPLATE): issue/PR templates + community docs."
echo "Smoke-check: open New issue on https://github.com/$FULL/issues/new/choose"
