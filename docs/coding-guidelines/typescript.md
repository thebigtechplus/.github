# TypeScript guidelines

Org addendum for TypeScript. Baseline: [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html). Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

Hard org rules ([CONTRIBUTING.md](../../CONTRIBUTING.md#tech-stack)): **servers and APIs run on the [Bun](https://bun.sh/) runtime**, and packages are managed with **pnpm or bun only — npm is banned** (pre-commit rejects `package-lock.json`). TypeScript on Bun is the default web backend.

## Tooling

- [Biome](https://biomejs.dev/) for formatting and linting — one tool, one config.
- `bun test` as the test runner.

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

- Feature directories, not layer directories (`billing/`, not `controllers/` + `services/` + `models/`).
- `index.ts` barrels only at feature boundaries — no barrel-of-barrels re-export chains.
- Tests live next to the code as `*.test.ts`.

## Naming

| Kind | Convention | Example |
| --- | --- | --- |
| File | `kebab-case.ts` | `invoice-service.ts` |
| Variable / function | `camelCase` | `parseInvoice` |
| Type / class / interface | `PascalCase`, no `I` prefix | `InvoiceStore` |
| Constant | `UPPER_SNAKE` for module constants | `MAX_RETRIES` |
| Test | `describe(feature)` + `it(scenario)` | `it("rejects a missing total")` |

## Error handling

- Throw `Error` subclasses with a `cause`; or use Result-style returns — pick one per project and stay consistent.
- Every `catch` either handles, translates, or rethrows — never an empty catch.
- **Validate at the boundary:** all external input (HTTP bodies, env, queue messages) goes through [zod](https://zod.dev/) (or equivalent) before touching domain code.

```typescript
const Invoice = z.object({ id: z.string(), total: z.number().positive() });
type Invoice = z.infer<typeof Invoice>;

const parsed = Invoice.safeParse(await req.json());
if (!parsed.success) return Response.json({ error: "invalid invoice" }, { status: 400 });
```

## Design patterns

- **Discriminated unions + exhaustive `switch`** over class hierarchies for variant data:

```typescript
type Payment =
  | { kind: "card"; last4: string }
  | { kind: "transfer"; bankRef: string };
```

- `type` for data shapes and unions; `interface` only for object contracts meant to be implemented.
- **Dependency injection by parameter** — pass collaborators into factory functions; no global service locators, no DI frameworks.
- Prefer plain functions + modules; classes only when state and behavior genuinely belong together.

Anti-patterns: `any` (needs a justifying comment; prefer `unknown` + narrowing), TypeScript `enum` (use `as const` unions), Node-isms where Bun natives exist, `.then()` chains, npm anything.

## Concurrency

- `async`/`await` only; no raw `.then` chains, no fire-and-forget promises — every promise is awaited or explicitly handed to a supervisor.
- `AbortController`/`AbortSignal` for cancellation and timeouts; pass signals through to fetch and long operations.
- `Promise.all` for independent work; `Promise.allSettled` when partial failure is acceptable and handled.

## APIs and services

API contract rules (URLs, status codes, errors, pagination): [api-design.md](api-design.md).

- `Bun.serve` directly for small services; [Hono](https://hono.dev/) when routing/middleware outgrows it.
- Prefer built-in Bun APIs (`Bun.file`, `bun:sqlite`, `Bun.env`) over Node polyfills where practical.
- Handlers stay thin: validate (zod) → call service → shape response.
- JSON fields `camelCase`; time is RFC 3339 UTC strings.

## Logging, config, and secrets

- Structured JSON logs (pino or a thin `console` JSON wrapper); no bare `console.log` in production paths.
- Config read from the environment at startup, validated with a zod schema into a typed object.
- Secrets only from the environment or a secret manager; `.env` files stay untracked.

## Testing

- `bun test` with `describe`/`it`; test files beside the code.
- Fakes over mocking libraries: implement the same function/object contract the code consumes.
- HTTP handlers are tested by calling the fetch handler with a `Request` and asserting on the `Response` — no network.
