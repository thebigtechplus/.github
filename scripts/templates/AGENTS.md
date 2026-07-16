# Agent instructions

Instructions for AI coding agents (Claude Code, Codex, Cursor) working in this repository. Org-wide standards: [thebigtechplus/.github](https://github.com/thebigtechplus/.github).

## Project

<!-- Fill in: one short paragraph — what this repository is, the main language/framework, and where the entry points live. -->

## Commands

<!-- Fill in the commands agents should use here. Example:

- Setup: `pnpm install`
- Build: `pnpm build`
- Test: `pnpm test` (run before every commit)
- Lint: `pnpm lint`
-->

## Git conventions

- Branch from `main`. Name branches `type/issue-number-brief-description` (for example, `feat/12-add-login`).
- Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, ...). The commitizen commit-msg hook enforces this.
- Make small, focused commits. Do not batch unrelated changes into one commit.
- Let pre-commit hooks run. Never bypass them with `git commit --no-verify`.
- Add or update tests when a change alters behavior.

## Pull requests

- Target `main` and fill in every section of the pull request template, including how the change was verified.
- Link the related issue when one exists.
- Reviews come from `@thebigtechplus/admins` via CODEOWNERS. Merges are squash-only.

## Security

- Never read, print, or commit secrets, credentials, API keys, or customer data.
- Report security issues per the [org security policy](https://github.com/thebigtechplus/.github/blob/main/SECURITY.md) — never in a public issue.

## Boundaries

- Do not edit `CLAUDE.md` — it only imports this file. Add agent guidance here instead.
- Do not change `LICENSE` (proprietary) or add license/copyright headers to files.
- Full contribution standards: [CONTRIBUTING](https://github.com/thebigtechplus/.github/blob/main/CONTRIBUTING.md).
