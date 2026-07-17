# Coding guidelines

Coding style for all BigTech+ repositories. We adopt authoritative public style guides per language and keep an org addendum on top — when something is not covered here, follow the adopted guide.

Primary languages are **Go, Python, TypeScript, and Rust** (see [CONTRIBUTING.md](../CONTRIBUTING.md#tech-stack)). Starting a project in another language requires admin sign-off.

## Language guides

| Language | Guide | Formatter / linter |
| --- | --- | --- |
| Go | [coding-guidelines/go.md](coding-guidelines/go.md) | gofmt, golangci-lint |
| Python | [coding-guidelines/python.md](coding-guidelines/python.md) | ruff |
| TypeScript | [coding-guidelines/typescript.md](coding-guidelines/typescript.md) | Biome |
| Rust | [coding-guidelines/rust.md](coding-guidelines/rust.md) | rustfmt, clippy |

## Shared guides

| Topic | Guide |
| --- | --- |
| API design (URLs, errors, pagination, versioning) | [coding-guidelines/api-design.md](coding-guidelines/api-design.md) |
| Database and migrations | [coding-guidelines/database.md](coding-guidelines/database.md) |
| Security engineering | [coding-guidelines/security.md](coding-guidelines/security.md) |
| Code reviews | [coding-guidelines/reviews.md](coding-guidelines/reviews.md) |
| Documentation and comments | [coding-guidelines/documentation.md](coding-guidelines/documentation.md) |

## All languages

### Formatting and linting

- Run the formatter and linter before pushing; formatting is never up for review debate.
- CI runs format check + lint + tests on every pull request.

### Code structure

- **Organize by domain feature, not by technical layer.** A package/module named after what it does (`billing`, `auth`, `ingest`) beats one named after what it is (`utils`, `helpers`, `managers`, `models`). Dumping-ground modules are banned — when you reach for `utils`, find the domain the code belongs to.
- **One clear public entry point per package/module.** Keep the public surface small; everything else is private.
- **The dependency graph is acyclic and points inward:** handlers → services → domain → storage. The domain never imports the transport layer.
- Keep functions small and focused. Delete dead code — do not comment it out; git remembers.

### Design patterns

- **Patterns are vocabulary, not goals.** Reach for a pattern when the problem shape demands it, never to demonstrate one. The best design is the simplest one that survives the next requirement.
- **Prefer composition over inheritance** in every language, including the ones that make inheritance easy.
- **No speculative abstraction (YAGNI).** Do not add interfaces, generics, or plugin points for futures that may never arrive. Abstract at the second or third concrete use, not the first.
- **Dependency injection by constructor or parameter**, not by framework, global registry, or import-time side effect. A component's dependencies should be visible in its signature.
- **Favor immutability where it is cheap.** Mutate locally, share immutably.

### Errors

- Handle errors; never swallow them silently. An empty catch/except block needs a comment justifying it — and usually a redesign.
- Errors carry context (what was being attempted), not just the underlying cause.
- Fail fast at startup for configuration errors; degrade gracefully at runtime for request errors.

### Naming

- Names are written for the reader: no abbreviations that save three characters at the cost of a lookup.
- Name things after their domain meaning, not their type (`invoices`, not `invoiceList`).

### Logging, config, and secrets

- Structured logging (key-value or JSON) with levels; log lines are for machines first, humans second.
- Never log secrets, tokens, or personal data.
- Configuration comes from the environment; validate it at startup into a typed struct/object. No secrets in code or version control — gitleaks runs in pre-commit.

### Testing

- Behavior changes come with tests ([CONTRIBUTING.md](../CONTRIBUTING.md)).
- Test names describe the scenario and expectation, not the method under test.
- Tests are deterministic: no sleeps for synchronization, no dependence on external services without an explicit integration-test marker.
