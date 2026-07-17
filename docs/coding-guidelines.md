# Coding guidelines

Coding style for all BigTech+ repositories. We adopt authoritative public style guides per language and keep only a short org addendum on top — when something is not covered here, follow the adopted guide.

Primary languages are **Go, Python, TypeScript, and Rust** (see [CONTRIBUTING.md](../CONTRIBUTING.md#tech-stack)). Starting a project in another language requires admin sign-off.

## All languages

- Run the formatter and linter before pushing; formatting is never up for review debate.
- Keep functions small and focused. Delete dead code — do not comment it out.
- Handle errors; never swallow them silently.
- Behavior changes come with tests ([CONTRIBUTING.md](../CONTRIBUTING.md)).
- Names are written for the reader: no abbreviations that save three characters at the cost of a lookup.

## Go

Follow [Effective Go](https://go.dev/doc/effective_go) and the [Google Go Style Guide](https://google.github.io/styleguide/go/).

Org addendum:

- `gofmt` is mandatory; `go vet` and [golangci-lint](https://golangci-lint.run/) run in CI.
- Module paths: `github.com/thebigtechplus/<repo>`.
- Prefer table-driven tests with the standard `testing` package.
- Return errors with context (`fmt.Errorf("doing x: %w", err)`); do not panic in library code.

## Python

Follow [PEP 8](https://peps.python.org/pep-0008/) and the [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html).

Org addendum:

- [ruff](https://docs.astral.sh/ruff/) for both formatting and linting.
- Type hints are required on public functions and methods.
- [pytest](https://docs.pytest.org/) for tests.
- Pin runtime dependencies with a lock file (`uv.lock`, `poetry.lock`, or `requirements.txt` with hashes).

## TypeScript

Follow the [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html).

Org addendum:

- [Biome](https://biomejs.dev/) for formatting and linting.
- `"strict": true` in `tsconfig.json`; no `any` without a comment explaining why.
- **Servers and APIs run on the [Bun](https://bun.sh/) runtime** — not Node. Prefer built-in Bun APIs (`Bun.serve`, `bun:sqlite`, `Bun.file`) over Node polyfills where practical.
- Package manager: **pnpm or bun only; npm is banned.** Never commit `package-lock.json` or `npm-shrinkwrap.json` — pre-commit rejects them.
- [PHP and Laravel are banned](../CONTRIBUTING.md#tech-stack); TypeScript on Bun is the default for new web backends.

## Rust

Follow the [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/) and idiomatic style from [The Rust Programming Language](https://doc.rust-lang.org/book/).

Org addendum:

- `rustfmt` is mandatory; [clippy](https://doc.rust-lang.org/clippy/) warnings are errors in CI (`cargo clippy -- -D warnings`).
- `cargo test` for tests; unit tests live next to the code, integration tests in `tests/`.
- Prefer `Result` + `?` over `unwrap()`/`expect()` outside tests and `main`.
- Commit `Cargo.lock` for binaries; omit it for libraries.
