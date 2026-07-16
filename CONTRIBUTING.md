# Engineering standards

Standards for work in BigTech+ repositories. Repositories without their own guide inherit this file from [thebigtechplus/.github](https://github.com/thebigtechplus/.github).

## Tooling

Install and authenticate the [GitHub CLI](https://cli.github.com/) (`gh`). All developers use `gh` for repository bootstrap and common GitHub workflows.

```bash
gh extension install thebigtechplus/gh-bootstrap-repo
gh bootstrap-repo <repo-name> --create
```

See [docs/new-repo.md](docs/new-repo.md).

## AI-assisted development

BigTech+ developers use AI tools (Claude, Codex, Cursor) as assistants, not as authors of record.

- Canonical guidelines: [AGENTS.md](AGENTS.md) in each product repository (seeded by bootstrap)
- Claude Code: [CLAUDE.md](CLAUDE.md) imports `@AGENTS.md` — edit `AGENTS.md` only, not duplicate rules in `CLAUDE.md`
- You are responsible for reviewing, testing, and merging all AI-assisted changes
- Do not add AI co-author trailers to commits

## Conduct

Follow the [Code of Conduct](CODE_OF_CONDUCT.md). Report concerns to [conduct@bigtechplus.io](mailto:conduct@bigtechplus.io).

## Help and security

See [SUPPORT.md](SUPPORT.md). Report security issues using [SECURITY.md](SECURITY.md) — do not file them as normal issues.

## Branching

1. Branch from `main`.
2. Name branches `type/issue-number-brief-description` (for example, `feat/12-add-login` or `fix/34-header-alignment`).
3. Open a pull request against `main`.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Use |
| --- | --- |
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `style:` | Formatting that does not change behavior |
| `refactor:` | Code change that is not a fix or feature |
| `perf:` | Performance improvement |
| `test:` | Tests |
| `chore:` | Maintenance, tooling, or configuration |
| `ci:` | Continuous integration |

## Pre-commit

Product repositories seeded by bootstrap include `.pre-commit-config.yaml`. Install hooks once per clone:

```bash
pip install pre-commit   # or: brew install pre-commit
pre-commit install
pre-commit run --all-files   # optional first run
```

Hooks include: whitespace and EOF fixes, YAML checks, merge conflicts, large files, private keys, [Conventional Commits](https://www.conventionalcommits.org/) (commitizen), shellcheck, markdownlint, and gitleaks.

Add language-specific hooks in the repository when needed. Do not bypass hooks with `--no-verify` without a documented reason.

## Pull requests

1. Link the pull request to an issue when one exists.
2. Complete the pull request template.
3. Request review from at least one member of the [`admins`](https://github.com/orgs/thebigtechplus/teams/admins) team.
4. Ensure required checks pass.
5. Squash and merge after approval.

Product repositories should include a `CODEOWNERS` file that assigns `@thebigtechplus/admins` (this repository’s `CODEOWNERS` does not cascade to other repos).
