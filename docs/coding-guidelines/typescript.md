# TypeScript guidelines

Org addendum for TypeScript. Baseline: [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html). Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

Hard org rules ([CONTRIBUTING.md](../../CONTRIBUTING.md#tech-stack)): **servers and APIs run on the [Bun](https://bun.sh/) runtime**, and packages are managed with **pnpm or bun only — npm is banned** (pre-commit rejects `package-lock.json`). TypeScript on Bun is the default web backend. One runtime and one lockfile format across the org means every service starts, debugs, and deploys the same way — the alternative is per-repo toolchain archaeology.

## Tooling

- [Biome](https://biomejs.dev/) for formatting and linting — one tool, one config, replacing the prettier + eslint + plugin pile; it is fast enough to run on every save and every commit, and rules never fight the formatter.
- `bun test` as the test runner — built into the runtime we already ship, so tests exercise the same engine that runs production code, with no jest/ts-jest transform layer to configure or debug.

```bash
biome check --write .
bun test
bunx tsc --noEmit
```

`biome.json` baseline:

```json
{
  "formatter": { "indentStyle": "space" },
  "linter": { "rules": { "recommended": true } }
}
```

`tsconfig.json` must set:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true
  }
}
```

`strict` off means `null` and `undefined` flow silently into every type — the single largest source of runtime crashes TypeScript exists to prevent. `noUncheckedIndexedAccess` closes the remaining hole: `array[i]` is `T | undefined`, matching what actually happens at runtime.

## Project structure

```text
myservice/
├── package.json
├── bunfig.toml
├── biome.json
├── tsconfig.json
├── src/
│   ├── index.ts           # entry point: config, wiring, Bun.serve
│   ├── billing/           # one directory per domain feature
│   │   ├── index.ts       # public surface of the feature
│   │   ├── invoice.ts
│   │   └── invoice.test.ts
│   ├── http/              # transport layer (routes, middleware)
│   └── storage/           # persistence layer
└── bun.lock
```

- Feature directories, not layer directories (`billing/`, not `controllers/` + `services/` + `models/`) — a feature change should touch one directory, not four; layer directories turn every feature into a tree-wide scavenger hunt.
- `index.ts` barrels only at feature boundaries — no barrel-of-barrels re-export chains. Deep barrel chains create accidental circular imports (evaluating to `undefined` at runtime with no error) and drag the whole feature into every bundle that wanted one function.
- Tests live next to the code as `*.test.ts` — proximity keeps them updated in the same PR; a distant `__tests__` tree is where tests go to fall behind.

## Naming

| Kind | Convention | Example |
| --- | --- | --- |
| File | `kebab-case.ts` | `invoice-service.ts` |
| Variable / function | `camelCase` | `parseInvoice` |
| Type / class / interface | `PascalCase`, no `I` prefix | `InvoiceStore` |
| Constant | `UPPER_SNAKE` for module constants | `MAX_RETRIES` |
| Test | `describe(feature)` + `it(scenario)` | `it("rejects a missing total")` |

Kebab-case filenames avoid the classic cross-platform trap: macOS is case-insensitive and git is not, so `InvoiceService.ts` vs `invoiceservice.ts` builds locally and breaks in CI.

## Error handling

- Throw `Error` subclasses with a `cause`; or use Result-style returns — pick one per project and stay consistent, because a codebase where callers cannot predict whether failures throw or return is one where every failure path is handled twice or not at all.
- Every `catch` either handles, translates, or rethrows — never an empty catch; a swallowed exception resurfaces as corrupted state three functions later, minus the stack trace that would have identified it.
- **Validate at the boundary:** all external input (HTTP bodies, env, queue messages) goes through [zod](https://zod.dev/) (or equivalent) before touching domain code. TypeScript types are erased at runtime — `as Invoice` on a network payload is a wish, not a check; zod turns the wish into a runtime guarantee and infers the static type from the same schema, so the two can never drift.

```typescript
const Invoice = z.object({ id: z.string(), total: z.number().positive() });
type Invoice = z.infer<typeof Invoice>;

const parsed = Invoice.safeParse(await req.json());
if (!parsed.success) return Response.json({ error: "invalid invoice" }, { status: 400 });
```

## Design patterns

- **Discriminated unions + exhaustive `switch`** over class hierarchies for variant data — when someone adds a third payment kind, the compiler lists every switch that fails to handle it; with a class hierarchy, the forgotten branch is found by a customer:

```typescript
type Payment =
  | { kind: "card"; last4: string }
  | { kind: "transfer"; bankRef: string };
```

- `type` for data shapes and unions; `interface` only for object contracts meant to be implemented — one convention, so the choice carries information instead of author habit. (Interfaces also merge declarations silently, which is almost never what you meant.)
- **Dependency injection by parameter** — pass collaborators into factory functions; no global service locators, no DI frameworks. Visible dependencies make the wiring readable and the fakes trivial; a locator hides the graph and turns a missing binding into a runtime error.
- Prefer plain functions + modules; classes only when state and behavior genuinely belong together — a class with one public method is a closure with ceremony.

Anti-patterns: `any` (it disables checking not just here but for everything the value touches downstream — one `any` at a boundary can silently unteype half a module; needs a justifying comment, prefer `unknown` + narrowing), TypeScript `enum` (generates runtime objects with surprising number/string duality; `as const` unions are erased at compile time and behave like plain strings everywhere), Node-isms where Bun natives exist, `.then()` chains, npm anything.

## Concurrency

- `async`/`await` only; no raw `.then` chains — mixed styles make control flow and error propagation hard to trace, and `try/catch` does not cover a stray `.then`. No fire-and-forget promises: an unawaited promise's rejection vanishes (or kills the process, depending on runtime flags) with a stack trace pointing nowhere. Every promise is awaited or explicitly handed to a supervisor.
- `AbortController`/`AbortSignal` for cancellation and timeouts; pass signals through to fetch and long operations — without cancellation, a client that gave up still costs you the full backend fan-out.
- `Promise.all` for independent work; `Promise.allSettled` when partial failure is acceptable and handled — `all` rejects on the first failure while the surviving promises keep running unobserved, so choose deliberately.

## APIs and services

API contract rules (URLs, status codes, errors, pagination): [api-design.md](api-design.md).

- `Bun.serve` directly for small services; [Hono](https://hono.dev/) when routing/middleware outgrows it — start with zero dependencies and add the framework when the need is demonstrated, not anticipated.
- Prefer built-in Bun APIs (`Bun.file`, `bun:sqlite`, `Bun.env`) over Node polyfills where practical — natives are faster and better supported; the compatibility layer exists for migration, not as a first choice.
- Handlers stay thin: validate (zod) → call service → shape response — business logic in handlers can only be tested through HTTP.
- JSON fields `camelCase`; time is RFC 3339 UTC strings.

## Logging, config, and secrets

- Structured JSON logs (pino or a thin `console` JSON wrapper); no bare `console.log` in production paths — unstructured lines cannot be filtered, aggregated, or alerted on.
- Config read from the environment at startup, validated with a zod schema into a typed object — `process.env.TYPO` is `undefined`, and undefined config should fail the boot, not the hundredth request.
- Secrets only from the environment or a secret manager; `.env` files stay untracked — one accidental commit of `.env` is a full credential rotation.

## Testing

- `bun test` with `describe`/`it`; test files beside the code.
- Fakes over mocking libraries: implement the same function/object contract the code consumes — a fake is plain TypeScript the compiler checks against the real contract; mock-DSL expectations couple tests to call counts and argument order, so refactors break tests that should not care.
- HTTP handlers are tested by calling the fetch handler with a `Request` and asserting on the `Response` — no network, no port binding, no flakiness; the fetch API makes handlers pure functions from request to response, so test them as functions.
