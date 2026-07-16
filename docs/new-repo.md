# New repository checklist

Use this when creating a private product repository under `thebigtechplus`.

Organization defaults (issue/PR templates, `CONTRIBUTING`, `SECURITY`, `SUPPORT`, `CODE_OF_CONDUCT`) inherit from [thebigtechplus/.github](https://github.com/thebigtechplus/.github) when the new repo does not define its own copies. Keep this `.github` repository **public**.

## 1. Create the repository

- Owner: `thebigtechplus`
- Visibility: **Private** (unless it is intentionally open source)
- Default branch: `main`
- Do **not** add a local `.github/ISSUE_TEMPLATE/` folder unless you mean to override org defaults

## 2. Copy CODEOWNERS

Org `CODEOWNERS` does not inherit. Add a root `CODEOWNERS` file:

```
* @thebigtechplus/developers
```

## 3. Create labels

Issue forms apply these labels. Create them in the new repository (Settings → Labels, or `gh label create`):

| Name | Suggested color | Purpose |
| --- | --- | --- |
| `bug` | `#d73a4a` | Bug reports |
| `enhancement` | `#a2eeef` | Feature requests |
| `dependencies` | `#0366d6` | Dependency updates (if using Dependabot) |
| `github-actions` | `#2088FF` | Actions-related Dependabot PRs (optional) |

Example:

```bash
gh label create bug --color d73a4a --description "Something isn't working"
gh label create enhancement --color a2eeef --description "New feature or request"
gh label create dependencies --color 0366d6 --description "Dependency updates"
gh label create github-actions --color 2088FF --description "GitHub Actions related"
```

## 4. Branch protection on `main`

In Settings → Branches → Add rule for `main` (recommended):

- Require a pull request before merging
- Require approvals: at least 1
- Prefer requiring review from Code Owners once `CODEOWNERS` exists
- Do not allow force pushes
- Do not allow deletions

Exact UI options vary; match this intent on GitHub Free.

## 5. Optional: Dependabot

To update GitHub Actions in the product repo, copy [`.github/dependabot.yml`](../.github/dependabot.yml) into that repository. Add package ecosystems later when the stack needs them.

## 6. Optional: CI

Add workflows under the product repo’s `.github/workflows/` when you have real checks (lint, test, build). Do not add empty placeholder workflows.

## 7. Smoke-check inheritance

1. Open **New issue** — you should see **Bug Report** and **Feature Request**.
2. Open a test PR — the PR template should appear.
3. Confirm the Security and Contributing links appear in the repository community/standards UI where applicable.

If the issue chooser is empty, the repo likely has its own `.github/ISSUE_TEMPLATE/` that overrides org defaults. Remove it to inherit again.
