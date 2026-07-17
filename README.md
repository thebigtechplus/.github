<h1 align="center">BigTech+ <code>.github</code> repository</h1>

<p align="center">
  <b>English</b> | <a href="README.my.md">မြန်မာ</a>
</p>

Canonical GitHub defaults and engineering standards for the [BigTech+](https://github.com/thebigtechplus) organization.

BigTech+ is primarily a **private** organization. This repository stays **public** because GitHub requires that for organization-wide community health files and issue/PR templates.

## What inherits automatically

Repositories that do not define their own copies can inherit:

| Path | Purpose |
| --- | --- |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Expected conduct |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Branching, commits, and review process |
| [`SECURITY.md`](SECURITY.md) | How to report security issues |
| [`SUPPORT.md`](SUPPORT.md) | Where to get help |
| [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/) | Bug and feature issue forms |
| [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md) | Pull request checklist |

## What does not inherit

Copy these into each product repository (or configure there) when needed:

| Path | Purpose |
| --- | --- |
| [`CODEOWNERS`](CODEOWNERS) | Review ownership (`@thebigtechplus/admins`) |
| [`scripts/templates/`](scripts/templates/) | README, AGENTS, CLAUDE, proprietary LICENSE, pre-commit templates for bootstrap |
| [`.github/dependabot.yml`](.github/dependabot.yml) | Dependency update automation |
| Workflows under `.github/workflows/` | CI/CD (add real workflows when products need them) |

Issue form labels (`bug`, `enhancement`) must also exist in each repository that uses the inherited forms.

## New repositories

**Requires [GitHub CLI](https://cli.github.com/)** (`gh`). Bootstrap **one repo at a time** (not all repos automatically).

Install the extension once:

```bash
gh extension install thebigtechplus/gh-bootstrap-repo
```

Then from anywhere:

```bash
gh bootstrap-repo <repo-name> --create              # private (default)
gh bootstrap-repo <repo-name> --create --public     # public
```

One-liners and details: [`docs/new-repo.md`](docs/new-repo.md).

## Profile

[`profile/README.md`](profile/README.md) is shown on [github.com/thebigtechplus](https://github.com/thebigtechplus).

## Website

- [www.bigtechplus.io](https://www.bigtechplus.io)
