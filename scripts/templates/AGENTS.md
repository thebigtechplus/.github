# AI-assisted development

Guidelines for using AI coding tools at BigTech+.

## Approved tools

- Claude (Claude Code)
- Codex
- Cursor

## Responsibilities

- AI is assistive. You are responsible for every change you commit and merge.
- Review and understand all AI-generated code before opening a pull request.
- Add or update tests when AI changes behavior.
- Follow [CONTRIBUTING.md](CONTRIBUTING.md) (branching, Conventional Commits, pull request template).

## Security and privacy

- Do not paste secrets, credentials, API keys, or customer data into AI prompts.
- Report security issues using [SECURITY.md](SECURITY.md). Do not discuss vulnerabilities in AI chats as a substitute for private reporting.

## Commits and attribution

- Do not add AI co-author trailers to commits (for example, `Co-authored-by` lines for tools).
- Write commit messages yourself using [Conventional Commits](https://www.conventionalcommits.org/).
- Run `pre-commit run --all-files` before pushing when hooks are installed. Do not use `git commit --no-verify` to skip checks without a documented reason.

## Pull requests

- Describe what changed and how you verified it in the pull request template.
- Request review from the `admins` team per CODEOWNERS.
