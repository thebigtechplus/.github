# Rust guidelines

Org addendum for Rust. Baseline: [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/) and idiomatic style from [The Rust Programming Language](https://doc.rust-lang.org/book/). Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

## Tooling

- `rustfmt` is mandatory; [clippy](https://doc.rust-lang.org/clippy/) warnings are errors in CI — clippy encodes hundreds of community-learned pitfalls, and treating warnings as errors is the only setting under which they stay at zero; any tolerated warning count only ever grows.

```bash
cargo fmt --check
cargo clippy --all-targets -- -D warnings
cargo test
```

## Project structure

Binary crate:

```text
myservice/
├── Cargo.toml
├── Cargo.lock            # committed for binaries, omitted for libraries
├── src/
│   ├── main.rs           # wiring only: config, dependencies, start
│   ├── billing/          # one module per domain feature
│   │   ├── mod.rs
│   │   └── invoice.rs
│   ├── http/             # transport layer (axum routers)
│   └── storage/          # persistence layer
└── tests/
    └── api.rs            # integration tests
```

Multi-crate projects use a workspace with one crate per deployable/library — crates are the unit of compilation and of visibility enforcement, so splitting along real boundaries buys parallel builds and honest APIs. Shared domain types get their own crate rather than a `common` dumping ground: `common` accretes unrelated exports until every crate depends on all of it and incremental compilation is defeated.

## Naming

| Kind | Convention | Example |
| --- | --- | --- |
| Crate / module | `snake_case` | `billing` |
| Function / variable | `snake_case` | `parse_invoice` |
| Type / trait / enum | `PascalCase` | `InvoiceStore` |
| Constant / static | `UPPER_SNAKE` | `MAX_RETRIES` |
| Conversion methods | `as_` / `to_` / `into_` per API guidelines | `to_string`, `into_bytes` |
| Test | `snake_case` scenario | `parse_invoice_missing_total` |

The `as_`/`to_`/`into_` prefixes are a cost contract, not decoration: `as_` is a free borrow, `to_` allocates, `into_` consumes — a caller reads the performance implication straight from the name.

## Error handling

- Libraries define error enums with [`thiserror`](https://docs.rs/thiserror); binaries may use [`anyhow`](https://docs.rs/anyhow) at the top level. The split follows who needs what: a library's callers must be able to `match` on failure modes, so the type must enumerate them; a binary's `main` only reports errors, so a uniform boxed error with context is enough.
- Propagate with `?`. No `unwrap()`/`expect()` outside tests, examples, and `main` — every `unwrap` is a panic scheduled for the input you did not anticipate, and it takes down the whole process, not just the request. `expect()` messages state the violated invariant ("config validated at startup"), so the panic that "cannot happen" explains itself when it does.
- Errors are enums callers can match on, not strings — string errors force callers into substring matching, which silently breaks the day someone rewords a message.

```rust
#[derive(Debug, thiserror::Error)]
pub enum InvoiceError {
    #[error("invoice {0} not found")]
    NotFound(InvoiceId),
    #[error("storage: {0}")]
    Storage(#[from] sqlx::Error),
}
```

## Design patterns

- **Newtype pattern** for domain identifiers and units — `struct InvoiceId(String)` beats passing bare `String`s: with three string parameters in a row, the compiler cannot catch a swapped argument; with newtypes it is a type error. Zero runtime cost.
- **Builder pattern** for structs with several optional fields; derive it or write it by hand, but don't take ten positional arguments — call sites with ten positionals are unreadable and fragile under reordering; builders name every field and let you add one without touching existing callers.
- **Ownership is the design tool:** decide who owns each value; borrow by default, clone deliberately. The borrow checker is not an obstacle to appease — the fights it picks are design feedback, usually telling you the ownership story is muddled.
- **Typestate** where compile-time state machines pay for themselves (e.g. a request that cannot be sent twice) — encoding states as types moves "called in the wrong order" from a runtime bug to a compile error. Not everywhere: the type gymnastics tax is real, so spend it only where misuse is costly.
- Traits are defined by the consumer that needs the abstraction, kept small, and implemented for concrete types — the consumer knows which capabilities it actually requires; implementer-defined traits guess, and guess big.

Anti-patterns: `clone()` to silence the borrow checker (each such clone is a hidden allocation *and* a suppressed design signal — the checker was pointing at a real ownership question), `Arc<Mutex<_>>` as the default sharing strategy (it reintroduces the shared-mutable-state model Rust's ownership system exists to replace; prefer message passing or rethink who owns the data), stringly-typed errors, `pub` on everything (every `pub` item is API you must maintain forever; Rust's privacy is your refactoring freedom).

## Concurrency

- [tokio](https://tokio.rs/) is the async runtime for services; spawned tasks are tracked (`JoinSet`/handles), never detached fire-and-forget — a detached task's panic is silently swallowed, and at shutdown you cannot wait for work you never tracked.
- Channels (`mpsc`, `oneshot`, `watch`) for task communication; share state via message passing before reaching for locks — channels make ownership transfer explicit and deadlock-free by construction; lock graphs have to be reasoned about globally.
- Hold locks across the smallest scope possible and **never across an `.await`** — the task can be suspended indefinitely at that point while every other task piles up behind the lock; with a std `Mutex` this deadlocks outright.
- CPU-bound work goes to `spawn_blocking` or rayon, not the async executor — tokio multiplexes many tasks onto few threads, so one long computation stalls every task sharing that worker.

## APIs and services

API contract rules (URLs, status codes, errors, pagination): [api-design.md](api-design.md).

- [axum](https://docs.rs/axum) is the default web framework; extractors validate input at the boundary (serde + validation), handlers stay thin — extractors turn "forgot to validate" into a type error, since the handler cannot even be called without successfully parsed input.
- JSON fields `camelCase` via `#[serde(rename_all = "camelCase")]`; time is RFC 3339 UTC (`chrono`/`time` with serde).
- Servers support graceful shutdown (signal → drain connections → stop) — a hard kill mid-request turns deploys into a source of user-visible errors and half-completed writes.

## Logging, config, and secrets

- [`tracing`](https://docs.rs/tracing) with structured fields; spans around units of work; JSON output in production — spans carry request context through async boundaries where a thread-local logger loses the plot, so every line of a request's lifetime is correlatable.
- Config from environment variables into a typed struct at startup (hand-rolled, `envy`, or `figment`), validated before the server binds — config errors should fail the deploy, not the first request that exercises the missing value.
- Secrets only from the environment or a secret manager.

## Testing

- Unit tests in a `#[cfg(test)] mod tests` next to the code; integration tests in `tests/` — the split is what it tests: unit tests may use internals; `tests/` compiles as an external crate, so it exercises exactly the public API your users get.
- Test the public API of each module; fakes implement the consumer-defined traits — tests against internals break on every refactor without catching anything, teaching people to rubber-stamp test failures.
- Property-based tests ([proptest](https://docs.rs/proptest)) where invariants matter more than examples — hand-picked examples encode the failures you already thought of; generated cases find the ones you did not (empty input, `i64::MAX`, invalid UTF-8). `cargo test` runs everything deterministically.
