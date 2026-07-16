# Contributing to BigTech+

Thank you for contributing. This guide applies to repositories that inherit organization defaults from [thebigtechplus/.github](https://github.com/thebigtechplus/.github).

## Code of conduct

Participation is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). Report concerns to [conduct@bigtechplus.io](mailto:conduct@bigtechplus.io).

## Getting help

See [SUPPORT.md](SUPPORT.md) for where to ask questions and how to report bugs or request features. Report security issues privately using [SECURITY.md](SECURITY.md).

## Branching

Use a feature-branch workflow:

1. Branch from `main`.
2. Name branches `type/issue-number-brief-description` (for example, `feat/12-add-login` or `fix/34-header-alignment`).
3. Open a pull request against `main`.

## Commit messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Use |
| --- | --- |
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `style:` | Formatting that does not change behavior |
| `refactor:` | Code change that is not a fix or feature |
| `test:` | Tests |
| `chore:` | Maintenance, tooling, or configuration |
| `ci:` | Continuous integration |

## Pull requests

1. Link the pull request to an issue when one exists.
2. Complete the pull request template.
3. Request review from at least one member of the [`developers`](https://github.com/orgs/thebigtechplus/teams/developers) team.
4. Ensure required checks pass.
5. Squash and merge after approval.

Product repositories should use `@thebigtechplus/developers` in `CODEOWNERS` so the same team is requested for review by default.
