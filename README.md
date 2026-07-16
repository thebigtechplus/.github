# BigTech+ organization defaults

This repository provides default community health files, issue and pull request templates, and shared GitHub Actions for the [BigTech+](https://github.com/thebigtechplus) organization.

Repositories in the organization that do not define their own copies inherit these defaults.

## Contents

| Path | Purpose |
| --- | --- |
| [`profile/README.md`](profile/README.md) | Organization profile shown on [github.com/thebigtechplus](https://github.com/thebigtechplus) |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Community standards (Contributor Covenant) |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to contribute |
| [`SECURITY.md`](SECURITY.md) | Vulnerability reporting policy |
| [`SUPPORT.md`](SUPPORT.md) | Where to get help |
| [`CODEOWNERS`](CODEOWNERS) | Default review ownership for this repository |
| [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/) | Bug report and feature request forms |
| [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md) | Default pull request checklist |
| [`.github/workflows/`](.github/workflows/) | Reusable workflows for other repositories |
| [`.github/dependabot.yml`](.github/dependabot.yml) | Dependabot updates for GitHub Actions in this repository |

## Website

- [www.bigtechplus.io](https://www.bigtechplus.io)

## Reusable workflows

Other repositories can call workflows from this repository, for example:

```yaml
jobs:
  ci:
    uses: thebigtechplus/.github/.github/workflows/reusable-ci.yml@main
```
