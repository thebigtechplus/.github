# New repository checklist

**Requires [GitHub CLI](https://cli.github.com/)** (`gh`), authenticated with access to `thebigtechplus`. All developers use `gh` for this workflow.

Organization defaults (issue/PR templates, `CONTRIBUTING`, `SECURITY`, `SUPPORT`, `CODE_OF_CONDUCT`) inherit from [thebigtechplus/.github](https://github.com/thebigtechplus/.github) when the new repo does not define its own copies. Keep this `.github` repository **public**.

## Recommended: `gh` extension (from anywhere)

Install once:

```bash
gh extension install thebigtechplus/gh-bootstrap-repo
```

Then, from any directory, bootstrap **one** repository at a time:

```bash
gh bootstrap-repo api --create              # private (default)
gh bootstrap-repo oss-demo --create --public
gh bootstrap-repo web                       # configure existing repo
```

Upgrade the extension:

```bash
gh extension upgrade bootstrap-repo
```

This does **not** apply to all repos automatically. Run it again for each new repository.

Extension source: [thebigtechplus/gh-bootstrap-repo](https://github.com/thebigtechplus/gh-bootstrap-repo).

## Alternative: one-liners (still requires `gh`)

The remote scripts call `gh` internally. Install and authenticate `gh` first.

```bash
# macOS / Linux / Git Bash / WSL
curl -fsSL https://raw.githubusercontent.com/thebigtechplus/.github/main/scripts/bootstrap-repo.sh | bash -s -- api --create
```

```powershell
# Windows PowerShell
$script = Join-Path $env:TEMP 'btp-bootstrap-repo.ps1'
Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/thebigtechplus/.github/main/scripts/bootstrap-repo.ps1' -OutFile $script
pwsh -File $script api -Create
```

## Local clone (optional)

If you already have this repo checked out:

| Platform | Command |
| --- | --- |
| macOS / Linux / Git Bash / WSL | `./scripts/bootstrap-repo.sh <repo-name> --create` |
| Windows (PowerShell) | `pwsh ./scripts/bootstrap-repo.ps1 <repo-name> -Create` |

## What bootstrap configures

- Labels: `bug`, `enhancement`, `dependencies`, `github-actions`
- Root `CODEOWNERS` → `@thebigtechplus/admins` (**only if missing**)
- Team access: `developers` (write), `admins` (admin)
- `README.md`, `AGENTS.md`, `CLAUDE.md` (from [`scripts/templates/`](../scripts/templates/) — **only if missing**)
- `LICENSE` — proprietary / all rights reserved (from templates — **only if missing**; replace only for intentional open source)
- `.pre-commit-config.yaml`, `.markdownlint.yaml` (from templates — **only if missing**)
- Squash-only merges, delete branch on merge, wiki off
- Branch protection: **not** applied by bootstrap — follow the printed web UI guide (or section below)

`AGENTS.md` is the canonical AI guidelines file (Claude, Codex, Cursor). `CLAUDE.md` imports `@AGENTS.md` for Claude Code only — do not duplicate rules there.

After bootstrap, install pre-commit locally:

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

Templates live in [scripts/templates/](../scripts/templates/).

## Manual checklist (same steps)

### 1. Create the repository

- Owner: `thebigtechplus`
- Visibility: **Private** (unless it is intentionally open source)
- Default branch: `main`
- Do **not** add a local `.github/ISSUE_TEMPLATE/` folder unless you mean to override org defaults

### 2. Copy CODEOWNERS

Org `CODEOWNERS` does not inherit. Add a root `CODEOWNERS` file:

```text
* @thebigtechplus/admins
```

### 3. Create labels

| Name | Suggested color | Purpose |
| --- | --- | --- |
| `bug` | `#d73a4a` | Bug reports |
| `enhancement` | `#a2eeef` | Feature requests |
| `dependencies` | `#0366d6` | Dependency updates (if using Dependabot) |
| `github-actions` | `#2088FF` | Actions-related Dependabot PRs (optional) |

### 4. Branch protection on `main` (manual)

Bootstrap prints a link and checklist when it finishes. Configure in the repository web UI:

**Settings → Rules → Rulesets** (or **Settings → Branches** for classic rules):
`https://github.com/thebigtechplus/<repo-name>/settings/rules`

Recommended for `main`:

- Require a pull request before merging
- Required approvals: at least 1
- Require review from Code Owners (after `CODEOWNERS` exists)
- Dismiss stale approvals when new commits are pushed
- Require conversation resolution before merging
- Restrict force pushes and deletions

On **GitHub Free**, branch protection for **private** org repositories may require upgrading the organization to **GitHub Team**, or making the repository **public**. Public repositories support branch protection on Free.

### 5. Optional: Dependabot

Copy [`.github/dependabot.yml`](../.github/dependabot.yml) into the product repository when needed.

### 6. Optional: CI

Add real workflows under `.github/workflows/` when you have lint/test/build checks. No placeholder workflows.

### 7. Smoke-check inheritance

1. **New issue** — Bug Report and Feature Request should appear.
2. Open a test PR — the PR template should appear.

If the issue chooser is empty, the repo likely has its own `.github/ISSUE_TEMPLATE/` overriding org defaults.
