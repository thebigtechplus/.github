# Coding guidelines

Coding style for all BigTech+ repositories. We adopt authoritative public style guides per language and keep an org addendum on top — when something is not covered here, follow the adopted guide. Standing on public guides means thousands of engineers have already debated these defaults; we spend our energy only on the deltas that are genuinely ours.

Primary languages are **Go, Python, TypeScript, and Rust** (see [CONTRIBUTING.md](../CONTRIBUTING.md#tech-stack)). Starting a project in another language requires admin sign-off — every extra language multiplies the tooling, review expertise, and hiring surface the org must maintain.

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
| API design (REST, GraphQL, gRPC, realtime, events) | [coding-guidelines/api-design.md](coding-guidelines/api-design.md) |
| Database and migrations | [coding-guidelines/database.md](coding-guidelines/database.md) |
| Security engineering | [coding-guidelines/security.md](coding-guidelines/security.md) |
| Code reviews | [coding-guidelines/reviews.md](coding-guidelines/reviews.md) |
| Documentation and comments | [coding-guidelines/documentation.md](coding-guidelines/documentation.md) |

## All languages

### Formatting and linting

- Run the formatter and linter before pushing; formatting is never up for review debate — style arguments consume review energy that should go into correctness, and a machine settles them for free.
- CI runs format check + lint + tests on every pull request, because a rule that is not enforced automatically decays into a suggestion within months.

### Code structure

- **Organize by domain feature, not by technical layer.** A package/module named after what it does (`billing`, `auth`, `ingest`) beats one named after what it is (`utils`, `helpers`, `managers`, `models`). Feature packages keep everything a change touches in one place — layer packages smear every feature across the whole tree, so each change becomes a five-directory scavenger hunt. Dumping-ground modules are banned because they grow monotonically: nobody ever moves code *out* of `utils`, and after two years it is an unreviewable junk drawer that everything imports. When you reach for `utils`, find the domain the code belongs to.
- **One clear public entry point per package/module.** Keep the public surface small; everything else is private. Every exported symbol is a promise you must keep — the smaller the surface, the more freedom you keep to refactor internals without breaking callers.
- **The dependency graph is acyclic and points inward:** handlers → services → domain → storage. The domain never imports the transport layer — the moment it does, you cannot test business logic without spinning up HTTP, and you cannot add a second transport (CLI, queue consumer) without surgery. Cycles are worse: they make code impossible to understand, test, or extract in isolation.
- Keep functions small and focused — a function that fits on one screen can be verified by reading; one that doesn't must be trusted. Delete dead code instead of commenting it out; git remembers everything, while commented-out blocks rot, mislead readers about what actually runs, and silently drift out of sync with the code around them.

### Design patterns

- **Patterns are vocabulary, not goals.** Reach for a pattern when the problem shape demands it, never to demonstrate one. Pattern-first code inverts the payoff: you carry the indirection cost on day one for flexibility that may never be exercised. The best design is the simplest one that survives the next requirement.
- **Prefer composition over inheritance** in every language, including the ones that make inheritance easy. Inheritance couples the child to the parent's implementation, not just its interface — a change to a base class ripples into every subclass, and deep hierarchies force readers to reconstruct behavior across five files. Composition keeps each piece testable and replaceable on its own.
- **No speculative abstraction (YAGNI).** Do not add interfaces, generics, or plugin points for futures that may never arrive. Abstract at the second or third concrete use, not the first — one use case gives you no information about which axis will actually vary, so early abstractions are usually wrong *and* expensive to unwind because callers have grown around them.
- **Dependency injection by constructor or parameter**, not by framework, global registry, or import-time side effect. When dependencies are visible in the signature, a reader knows the full recipe for the component and a test can substitute fakes without patching globals. Hidden wiring does the opposite: behavior changes at a distance, and tests fight the framework instead of the code.
- **Favor immutability where it is cheap.** Mutate locally, share immutably — shared mutable state is the root of an entire class of bugs (races, spooky action at a distance) that simply cannot occur when shared data cannot change.

### Errors

- Handle errors; never swallow them silently. A swallowed error does not disappear — it resurfaces later as corrupted data or a mystery failure, minus the context that would have made it debuggable. An empty catch/except block needs a comment justifying it, and usually a redesign.
- Errors carry context (what was being attempted), not just the underlying cause — "connection refused" tells you nothing; "syncing invoice inv_42 to billing: connection refused" tells you where to look.
- Fail fast at startup for configuration errors; degrade gracefully at runtime for request errors. A service that boots with a broken config fails at 3 a.m. on its first real request instead of at deploy time when someone is watching.

### Naming

- Names are written for the reader: no abbreviations that save three characters at the cost of a lookup. Code is read far more often than it is written, so every saved keystroke is paid back with interest by every future reader.
- Name things after their domain meaning, not their type (`invoices`, not `invoiceList`) — type information is already in the declaration and changes when the implementation does; meaning survives refactors.

### Logging, config, and secrets

- Structured logging (key-value or JSON) with levels; log lines are for machines first, humans second — you cannot alert on, filter, or aggregate free-form prose, and production debugging is a search problem.
- Never log secrets, tokens, or personal data — logs are copied into search indexes, third-party dashboards, and backups with far weaker access control than your database.
- Configuration comes from the environment; validate it at startup into a typed struct/object so a typo'd variable name fails the deploy instead of surfacing as a runtime mystery three requests in. No secrets in code or version control — git history is forever, and a leaked repo must not mean leaked credentials. gitleaks runs in pre-commit.

### Testing

- Behavior changes come with tests ([CONTRIBUTING.md](../CONTRIBUTING.md)) — an untested behavior change is a regression waiting for its trigger, and the test you write today is the only thing protecting your change from the next refactor.
- Test names describe the scenario and expectation, not the method under test — when `rejects_expired_token` fails, the reader knows what broke without opening the file; when `test_validate_2` fails, they know nothing.
- Tests are deterministic: no sleeps for synchronization, no dependence on external services without an explicit integration-test marker. A flaky test is worse than no test — the team learns to ignore red, and the one real failure hides among the noise.
