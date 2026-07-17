> မြန်မာဘာသာဖြင့် ဖတ်ရန် — [CONTRIBUTING.my.md](CONTRIBUTING.my.md)

# Engineering standards

Standards for work in BigTech+ repositories. Repositories without their own guide inherit this file from [thebigtechplus/.github](https://github.com/thebigtechplus/.github).

## Tooling

Install and authenticate the [GitHub CLI](https://cli.github.com/) (`gh`). All developers use `gh` for repository bootstrap and common GitHub workflows.

```bash
gh auth login

gh extension install thebigtechplus/gh-bootstrap-repo
gh bootstrap-repo <repo-name> --create
```

See [docs/new-repo.md](docs/new-repo.md).

## Tech stack

- **Primary languages: Go, Python, TypeScript, Rust.** Starting a project in another language requires sign-off from the [`admins`](https://github.com/orgs/thebigtechplus/teams/admins) team first.
- **JavaScript/TypeScript package managers: pnpm or bun only.** npm is banned — do not commit `package-lock.json` or `npm-shrinkwrap.json` (pre-commit rejects them).
- **TypeScript servers and APIs run on the [Bun](https://bun.sh/) runtime**, not Node.
- **Work conversation happens on Microsoft Teams and Slack only.** Do not move work discussion to personal messengers. Durable decisions belong in issues and pull requests, not chat.

Coding style: see [docs/coding-guidelines.md](docs/coding-guidelines.md).

## AI-assisted development

BigTech+ developers use AI tools (Claude, Codex, Cursor) as assistants, not as authors of record.

- Canonical guidelines: `AGENTS.md` in each product repository, seeded from [scripts/templates/AGENTS.md](scripts/templates/AGENTS.md)
- Claude Code: each repository's `CLAUDE.md` imports `@AGENTS.md` — edit `AGENTS.md` only, do not duplicate rules in `CLAUDE.md`
- You are responsible for reviewing, testing, and merging all AI-assisted changes

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

| Prefix      | Use                                      |
| ----------- | ---------------------------------------- |
| `feat:`     | New feature                              |
| `fix:`      | Bug fix                                  |
| `docs:`     | Documentation only                       |
| `style:`    | Formatting that does not change behavior |
| `refactor:` | Code change that is not a fix or feature |
| `perf:`     | Performance improvement                  |
| `test:`     | Tests                                    |
| `chore:`    | Maintenance, tooling, or configuration   |
| `ci:`       | Continuous integration                   |

## Pre-commit

Product repositories seeded by bootstrap include `.pre-commit-config.yaml`. Install hooks once per clone:

```bash
pip install pre-commit

pre-commit install
pre-commit run --all-files   # optional first run
```

Hooks include: whitespace and EOF fixes, YAML checks, merge conflicts, large files, private keys, [Conventional Commits](https://www.conventionalcommits.org/) (commitizen), shellcheck, markdownlint, and gitleaks.

Add language-specific hooks in the repository when needed. Do not bypass hooks with `--no-verify` without a documented reason.

## Pull requests

1. Link the pull request to an issue when one exists.
2. Complete the pull request template.
3. Request review from at least one member of the [admins](https://github.com/orgs/thebigtechplus/teams/admins) team.
4. Ensure required checks pass.
5. Merge following the [merging guidelines](#merging) below.

Product repositories should include a `CODEOWNERS` file that assigns responsible entity for the source code (this repository’s `CODEOWNERS` does not cascade to other repos).

## Merging

- **Squash and merge only.** Merge commits and rebase merges are disabled by bootstrap.
- **The pull request title becomes the commit on** `main`, so PR titles must follow [Conventional Commits](https://www.conventionalcommits.org/) (for example, `feat: add login flow`). Clean up the squash commit body before confirming the merge — keep it a short summary, not a list of intermediate commits.
- **Merge only when all of these hold:**
  1. At least one approval from the [admins](https://github.com/orgs/thebigtechplus/teams/admins) team.
  2. All required checks are green.
  3. All review conversations are resolved.
- **The author merges** after approval. Admins may merge on the author's behalf for abandoned or time-sensitive PRs.
- **Do not merge your own PR without review.** If you are the only maintainer of a repository, wait for review when the change is risky; use your judgment for trivial changes (docs, typos) and say so in the PR.
- Branches are deleted automatically on merge. Do not reuse a merged branch — start a new one from `main`.
- Keep pull requests small and focused. Split large work into a sequence of PRs that each merge cleanly on their own.

## License

New repositories get a proprietary `LICENSE` (all rights reserved) from bootstrap by default. Replace it only when a repository is intentionally open source.
