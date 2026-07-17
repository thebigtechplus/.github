# Go guidelines

Org addendum for Go. Baseline: [Effective Go](https://go.dev/doc/effective_go) and the [Google Go Style Guide](https://google.github.io/styleguide/go/). Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

## Tooling

- `gofmt` (or `goimports`) is mandatory — unformatted code does not merge. Go made formatting a solved problem on day one; reopening it buys nothing.
- `go vet` and [golangci-lint](https://golangci-lint.run/) run in CI — vet catches real bugs the compiler allows (misused Printf verbs, copied locks), and the linters encode years of community postmortems.

```bash
gofmt -l .
go vet ./...
golangci-lint run
go test ./...
```

## Project structure

```text
myservice/
├── cmd/
│   └── myservice/
│       └── main.go        # wiring only: config, dependencies, start
├── internal/
│   ├── billing/           # one package per domain feature
│   │   ├── billing.go     # public surface of the package
│   │   ├── invoice.go
│   │   └── billing_test.go
│   ├── httpserver/        # transport layer
│   └── storage/           # persistence layer
├── go.mod                 # module github.com/thebigtechplus/myservice
└── go.sum
```

- `main.go` stays thin — parse config, build dependencies, call into `internal/`. Logic in `main` is untestable (you cannot import package main), so anything beyond wiring is code you can never cover.
- Use `internal/` by default; `pkg/` only for code deliberately imported by other repositories. The compiler enforces `internal/` — outside modules cannot import it — which means you can refactor freely without breaking unknown consumers. Anything in `pkg/` is a public API you must maintain forever.
- One package per domain concept. No `util`, `common`, or `helpers` packages — they accrete unrelated code, everything ends up importing them, and they become the cycle-magnet at the center of the dependency graph.

## Naming

| Kind | Convention | Example |
| --- | --- | --- |
| Package | short, lowercase, no underscore | `billing` |
| Exported | MixedCaps | `ParseInvoice` |
| Unexported | mixedCaps | `parseInvoice` |
| Interface | behavior name, often `-er` | `InvoiceStore`, `Notifier` |
| Error variable | `Err` prefix | `ErrNotFound` |
| Test | `TestXxx_scenario` | `TestParseInvoice_missingTotal` |

Package names are part of every call site (`billing.Parse`, not `parse_invoice_util.DoParse`) — a good package name makes every caller more readable for free.

## Error handling

- Wrap with context and `%w`; inspect with `errors.Is` / `errors.As`. A bare `err` surfacing five layers up is unfindable; a wrapped chain ("handling request: loading invoice inv_42: query timeout") reads like a stack trace built from intent. `%w` keeps the chain machine-inspectable so callers can still branch on the root cause.
- Libraries return errors; only `main` decides to exit. No `panic` in library code — a panic takes down the whole process and steals the decision from the caller, who may have wanted to retry, degrade, or fail just that one request.
- Sentinel errors (`var ErrNotFound = errors.New(...)`) for conditions callers branch on; typed errors when callers need fields. String-matching on error text is the alternative, and it shatters the moment someone rewords a message.

```go
invoice, err := store.Get(ctx, id)
if err != nil {
    return fmt.Errorf("loading invoice %s: %w", id, err)
}
```

## Design patterns

- **Interfaces are defined by the consumer**, next to the code that uses them — not by the implementer. The consumer knows exactly which methods it needs (usually 1–3); the implementer can only guess, and guesses produce bloated interfaces nobody can fake in tests. This is the opposite of Java-style interface-first design, and it is why Go interfaces are satisfied implicitly.
- **Accept interfaces, return structs.** Accepting an interface gives callers maximum freedom to substitute fakes; returning a concrete struct keeps you free to add methods and fields without breaking implementers of a return-interface that never needed to exist.
- **Functional options** for constructors with optional settings — the alternative is either a growing list of positional parameters (every addition breaks all callers) or a config struct where zero values are ambiguous ("did they want 0, or did they not set it?"):

```go
func NewServer(addr string, opts ...Option) *Server
```

- **Dependency injection by constructor.** No global state, no `init()` side effects beyond `flag`/driver registration — globals make test order matter and hide the dependency graph; `init()` runs before `main` in import order, which is invisible at the call site and impossible to substitute in tests.

Anti-patterns: interface bloat (an interface with one implementation and no consumer-side need is pure indirection tax), `init()` magic, package-level mutable state, `context.Value` for passing dependencies — it is invisible in signatures, unchecked by the compiler, and turns a compile-time wiring error into a runtime nil.

## Concurrency

- `context.Context` is the first parameter of anything that blocks, does I/O, or spawns work — it is the only mechanism a caller has to enforce timeouts and cancel abandoned work; a function that ignores it holds resources for requests nobody is waiting on anymore.
- **The function that starts a goroutine owns its lifetime** — every goroutine has a defined exit path. A leaked goroutine is a slow memory leak *and* a data race waiting to fire during shutdown. Use [`errgroup`](https://pkg.go.dev/golang.org/x/sync/errgroup) for fan-out: it propagates the first error and waits for all workers, which is exactly the bookkeeping people get wrong by hand.
- Channels transfer ownership of data; mutexes protect shared state. Don't use channels as fancy mutexes — a channel-based lock is slower, harder to reason about, and deadlocks in ways a `sync.Mutex` cannot.
- Run `go test -race ./...` in CI — the race detector finds real interleavings that code review cannot; a race it reports is a bug even if you have never seen it fire.

## APIs and services

API contract rules (URLs, status codes, errors, pagination): [api-design.md](api-design.md).

- Standard library `net/http` first; add a router (e.g. `chi`) when routing outgrows it. The stdlib is where Go's compatibility promise lives — every framework you add is a dependency that can break, lag, or die.
- Handlers decode/validate input, call a service, encode output — no business logic in handlers. Logic in handlers can only be tested through HTTP, which is slower and couples your business rules to a transport.
- JSON fields are `camelCase` via struct tags; time is RFC 3339 UTC.
- Every server sets timeouts (`ReadTimeout`, `WriteTimeout`) and supports graceful shutdown via context cancellation — the zero values mean "no timeout", so a single slow-loris client can pin connections forever on a default server.

## Logging, config, and secrets

- `log/slog` with structured key-value pairs; one logger passed down, not a global — a passed logger can carry request-scoped fields (request ID, user) so every line in a request's lifetime is correlatable.
- Config is read from environment variables into a `Config` struct at startup and validated before anything else runs — scattered `os.Getenv` calls mean config errors surface mid-request instead of at boot.
- Secrets only from the environment or a secret manager — never flags (visible in `ps` output) and never files in the repo.

## Testing

- Table-driven tests with subtests (`t.Run`) — adding a case is one struct literal instead of a copy-pasted function, and each case reports its own name on failure.
- `httptest` for handlers; fakes written against consumer-defined interfaces. Prefer hand-written fakes over mock frameworks: a fake is plain Go anyone can read, while expectation-DSL mocks couple tests to call order and arguments, making refactors fail tests that should not care.
- Integration tests behind a build tag or `testing.Short()` guard, so the default `go test ./...` stays fast enough that people actually run it before pushing.
