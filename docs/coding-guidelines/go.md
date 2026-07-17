# Go guidelines

Org addendum for Go. Baseline: [Effective Go](https://go.dev/doc/effective_go) and the [Google Go Style Guide](https://google.github.io/styleguide/go/). Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

## Tooling

- `gofmt` (or `goimports`) is mandatory — unformatted code does not merge.
- `go vet` and [golangci-lint](https://golangci-lint.run/) run in CI.

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

- `main.go` stays thin — parse config, build dependencies, call into `internal/`.
- Use `internal/` by default; `pkg/` only for code deliberately imported by other repositories.
- One package per domain concept. No `util`, `common`, or `helpers` packages.

## Naming

| Kind | Convention | Example |
| --- | --- | --- |
| Package | short, lowercase, no underscore | `billing` |
| Exported | MixedCaps | `ParseInvoice` |
| Unexported | mixedCaps | `parseInvoice` |
| Interface | behavior name, often `-er` | `InvoiceStore`, `Notifier` |
| Error variable | `Err` prefix | `ErrNotFound` |
| Test | `TestXxx_scenario` | `TestParseInvoice_missingTotal` |

## Error handling

- Wrap with context and `%w`; inspect with `errors.Is` / `errors.As`.
- Libraries return errors; only `main` decides to exit. No `panic` in library code.
- Sentinel errors (`var ErrNotFound = errors.New(...)`) for conditions callers branch on; typed errors when callers need fields.

```go
invoice, err := store.Get(ctx, id)
if err != nil {
    return fmt.Errorf("loading invoice %s: %w", id, err)
}
```

## Design patterns

- **Interfaces are defined by the consumer**, next to the code that uses them — not by the implementer. Keep them small (1–3 methods).
- **Accept interfaces, return structs.**
- **Functional options** for constructors with optional settings:

```go
func NewServer(addr string, opts ...Option) *Server
```

- **Dependency injection by constructor.** No global state, no `init()` side effects beyond `flag`/driver registration.

Anti-patterns: interface bloat (an interface with one implementation and no consumer-side need), `init()` magic, package-level mutable state, `context.Value` for passing dependencies.

## Concurrency

- `context.Context` is the first parameter of anything that blocks, does I/O, or spawns work.
- **The function that starts a goroutine owns its lifetime** — every goroutine has a defined exit path. Use [`errgroup`](https://pkg.go.dev/golang.org/x/sync/errgroup) for fan-out with error propagation.
- Channels transfer ownership of data; mutexes protect shared state. Don't use channels as fancy mutexes.
- Run `go test -race ./...` in CI.

## APIs and services

- Standard library `net/http` first; add a router (e.g. `chi`) when routing outgrows it.
- Handlers decode/validate input, call a service, encode output — no business logic in handlers.
- JSON fields are `camelCase` via struct tags; time is RFC 3339 UTC.
- Every server sets timeouts (`ReadTimeout`, `WriteTimeout`) and supports graceful shutdown via context cancellation.

## Logging, config, and secrets

- `log/slog` with structured key-value pairs; one logger passed down, not a global.
- Config is read from environment variables into a `Config` struct at startup and validated before anything else runs.
- Secrets only from the environment or a secret manager — never flags, never files in the repo.

## Testing

- Table-driven tests with subtests (`t.Run`).
- `httptest` for handlers; fakes written against consumer-defined interfaces (prefer hand-written fakes over mock frameworks).
- Integration tests behind a build tag or `testing.Short()` guard.
