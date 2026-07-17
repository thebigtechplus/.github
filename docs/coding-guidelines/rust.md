# Rust guidelines

Org addendum for Rust. Baseline: [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/) and idiomatic style from [The Rust Programming Language](https://doc.rust-lang.org/book/). Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

## Tooling

- `rustfmt` is mandatory; [clippy](https://doc.rust-lang.org/clippy/) warnings are errors in CI.

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

Multi-crate projects use a workspace with one crate per deployable/library; shared domain types get their own crate rather than a `common` dumping ground with unrelated exports.

## Naming

| Kind | Convention | Example |
| --- | --- | --- |
| Crate / module | `snake_case` | `billing` |
| Function / variable | `snake_case` | `parse_invoice` |
| Type / trait / enum | `PascalCase` | `InvoiceStore` |
| Constant / static | `UPPER_SNAKE` | `MAX_RETRIES` |
| Conversion methods | `as_` / `to_` / `into_` per API guidelines | `to_string`, `into_bytes` |
| Test | `snake_case` scenario | `parse_invoice_missing_total` |

## Error handling

- Libraries define error enums with [`thiserror`](https://docs.rs/thiserror); binaries may use [`anyhow`](https://docs.rs/anyhow) at the top level.
- Propagate with `?`. No `unwrap()`/`expect()` outside tests, examples, and `main` — and `expect()` messages state the violated invariant.
- Errors are enums callers can match on, not strings.

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

- **Newtype pattern** for domain identifiers and units — `struct InvoiceId(String)` beats passing bare `String`s.
- **Builder pattern** for structs with several optional fields; derive it or write it by hand, but don't take ten positional arguments.
- **Ownership is the design tool:** decide who owns each value; borrow by default, clone deliberately.
- **Typestate** where compile-time state machines pay for themselves (e.g. a request that cannot be sent twice) — not everywhere.
- Traits are defined by the consumer that needs the abstraction, kept small, and implemented for concrete types.

Anti-patterns: `clone()` to silence the borrow checker, `Arc<Mutex<_>>` as the default sharing strategy (prefer message passing or redesign ownership), stringly-typed errors, `pub` on everything.

## Concurrency

- [tokio](https://tokio.rs/) is the async runtime for services; spawned tasks are tracked (`JoinSet`/handles), never detached fire-and-forget.
- Channels (`mpsc`, `oneshot`, `watch`) for task communication; share state via message passing before reaching for locks.
- Hold locks across the smallest scope possible and never across an `.await`.
- CPU-bound work goes to `spawn_blocking` or rayon, not the async executor.

## APIs and services

- [axum](https://docs.rs/axum) is the default web framework; extractors validate input at the boundary (serde + validation), handlers stay thin.
- JSON fields `camelCase` via `#[serde(rename_all = "camelCase")]`; time is RFC 3339 UTC (`chrono`/`time` with serde).
- Servers support graceful shutdown (signal → drain connections → stop).

## Logging, config, and secrets

- [`tracing`](https://docs.rs/tracing) with structured fields; spans around units of work; JSON output in production.
- Config from environment variables into a typed struct at startup (hand-rolled, `envy`, or `figment`), validated before the server binds.
- Secrets only from the environment or a secret manager.

## Testing

- Unit tests in a `#[cfg(test)] mod tests` next to the code; integration tests in `tests/`.
- Test the public API of each module; fakes implement the consumer-defined traits.
- Property-based tests ([proptest](https://docs.rs/proptest)) where invariants matter more than examples; `cargo test` runs everything deterministically.
