# New repository checklist

Use this when creating a private product repository under `thebigtechplus`.

Organization defaults (issue/PR templates, `CONTRIBUTING`, `SECURITY`, `SUPPORT`, `CODE_OF_CONDUCT`) inherit from [thebigtechplus/.github](https://github.com/thebigtechplus/.github) when the new repo does not define its own copies. Keep this `.github` repository **public**.

## Automated bootstrap (recommended)

The bootstrap script configures **one repository per run**. It does **not** apply to all repos automatically, and it does **not** run for future repos unless you invoke it again.

| Platform | Command |
| --- | --- |
| macOS / Linux / Git Bash / WSL | `./scripts/bootstrap-repo.sh <repo-name> --create` |
| Windows (PowerShell) | `pwsh ./scripts/bootstrap-repo.ps1 <repo-name> -Create` |

Examples:

```bash
# Create private repo "api" and configure it
./scripts/bootstrap-repo.sh api --create

# Configure an existing repo "web"
./scripts/bootstrap-repo.sh web
```

```powershell
pwsh ./scripts/bootstrap-repo.ps1 api -Create
pwsh ./scripts/bootstrap-repo.ps1 web
```

What the script sets on that repo:

- Labels: `bug`, `enhancement`, `dependencies`, `github-actions`
- Root `CODEOWNERS` → `@thebigtechplus/developers`
- Team access: `developers` (write), `admins` (admin)
- Squash-only merges, delete branch on merge, wiki off
- Branch protection on `main` (warns if GitHub Free limits block some rules)

Requirements: [GitHub CLI](https://cli.github.com/) installed and `gh auth login` completed.

## Manual checklist (same steps)

### 1. Create the repository

- Owner: `thebigtechplus`
- Visibility: **Private** (unless it is intentionally open source)
- Default branch: `main`
- Do **not** add a local `.github/ISSUE_TEMPLATE/` folder unless you mean to override org defaults

### 2. Copy CODEOWNERS

Org `CODEOWNERS` does not inherit. Add a root `CODEOWNERS` file:

```
* @thebigtechplus/developers
```

### 3. Create labels

| Name | Suggested color | Purpose |
| --- | --- | --- |
| `bug` | `#d73a4a` | Bug reports |
| `enhancement` | `#a2eeef` | Feature requests |
| `dependencies` | `#0366d6` | Dependency updates (if using Dependabot) |
| `github-actions` | `#2088FF` | Actions-related Dependabot PRs (optional) |

### 4. Branch protection on `main`

- Require a pull request before merging
- Require approvals: at least 1
- Prefer requiring review from Code Owners once `CODEOWNERS` exists
- Do not allow force pushes or deletions

Exact options vary on GitHub Free for private repositories.

### 5. Optional: Dependabot

Copy [`.github/dependabot.yml`](../.github/dependabot.yml) into the product repository when needed.

### 6. Optional: CI

Add real workflows under `.github/workflows/` when you have lint/test/build checks. No placeholder workflows.

### 7. Smoke-check inheritance

1. **New issue** — Bug Report and Feature Request should appear.
2. Open a test PR — the PR template should appear.

If the issue chooser is empty, the repo likely has its own `.github/ISSUE_TEMPLATE/` overriding org defaults.
