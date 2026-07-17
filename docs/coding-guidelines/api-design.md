# API design

Contract rules for all BigTech+ APIs, in every language and style. Consistent contracts mean a developer who has integrated one of our APIs already knows how the next one paginates, errors, and versions — that predictability is the entire value of these rules. Cross-language rules: [coding-guidelines.md](../coding-guidelines.md); language specifics: the per-language guides.

## Choosing a style

There is no single org-default style — each has a shape of problem it fits. Pick per interface, and record the choice and its reasons in an ADR ([documentation.md](documentation.md)) so the next team inherits the reasoning, not just the endpoint.

| Style | Fits when | Watch out for |
| --- | --- | --- |
| REST/JSON | Resource CRUD, public/product APIs, broad client compatibility, HTTP caching | Chatty for aggregate views |
| GraphQL | Many frontends with different data needs, client-driven aggregation | N+1 resolvers, unbounded queries, server complexity |
| gRPC | Service-to-service, low latency, streaming, strong typed contracts | Browser friction, binary payloads are harder to debug |
| WebSockets / SSE | Server push, live updates, bidirectional exchange | Connection state at scale, reconnect logic |
| Events / queues | Decoupled workflows, fan-out, absorbing traffic spikes | Eventual consistency, duplicate delivery |

- One product may mix styles — REST for CRUD, SSE for live updates, events between services — but **don't multiply styles within one interface without cause**: every additional style is another auth story, error story, monitoring story, and client stack to maintain forever.
- Shared principles below (auth, idempotency, field conventions) apply across all styles; the per-style sections add what is specific.

## REST / HTTP JSON

### Resources and URLs

- Resources are **plural nouns**: `/invoices`, `/invoices/{id}`, `/users/{id}/sessions` — consistent plurals mean nobody ever guesses wrong between `/invoice/42` and `/invoices/42`.
- Path segments are **kebab-case** (`/payment-methods`), path parameters `{camelCase}` — URLs are case-sensitive and get retyped from logs and docs; lowercase-with-dashes survives that round trip.
- Nest at most one level deep. If you need `/a/{id}/b/{id}/c`, promote `c` to a top-level resource with a filter (`/c?bId=`) — deep nesting forces clients to carry every ancestor ID to address a resource that has its own identity anyway.
- No verbs in URLs — the method *is* the verb; `POST /invoices/create` says create twice and eventually disagrees with itself. When an operation truly isn't CRUD, model it as a sub-resource action: `POST /invoices/{id}/send`.

### Methods

| Method | Use | Properties |
| --- | --- | --- |
| GET | Read | Safe, idempotent, cacheable — never mutates |
| POST | Create a resource; actions | Not idempotent (unless idempotency key) |
| PUT | Full replace | Idempotent |
| PATCH | Partial update | Send only changed fields |
| DELETE | Remove | Idempotent — deleting twice is not an error surface, return 404 or 204 consistently |

These properties are not etiquette — infrastructure acts on them. Proxies and browsers cache GETs and retry idempotent methods; a GET that mutates will be prefetched by a crawler, and a non-idempotent PUT breaks every retry layer between the client and you.

### Status codes

| Code | Use |
| --- | --- |
| 200 | Success with body |
| 201 | Created — include the new resource (and `Location` header) |
| 202 | Accepted for async processing — return a status URL |
| 204 | Success, no body (deletes, some updates) |
| 400 | Malformed request (unparseable body, wrong types) |
| 401 | Not authenticated |
| 403 | Authenticated but not allowed |
| 404 | Resource does not exist (also for hiding resources the caller may not see) |
| 409 | Conflict with current state (duplicate, stale version) |
| 422 | Well-formed but semantically invalid (validation failures) |
| 429 | Rate limited — include `Retry-After` |
| 500 | Unexpected server error — log it, never expose internals |
| 503 | Temporarily unavailable — include `Retry-After` when known |

Precise codes matter because clients branch on them mechanically: 4xx tells a client "fix your request, retrying is pointless", 5xx and 429 tell it "back off and retry". An API that returns 200 with an error body — or 500 for a validation failure — breaks every generic retry and monitoring layer its consumers rely on.

### Error format

One error envelope org-wide:

```json
{
  "error": {
    "code": "INVOICE_NOT_FOUND",
    "message": "Invoice inv_123 does not exist.",
    "details": [{ "field": "total", "issue": "must be positive" }]
  }
}
```

- `code` is machine-readable `SCREAMING_SNAKE`, stable across releases — clients branch on it. Without a stable code, clients parse the human message, and rewording an error becomes a breaking change.
- `message` is human-readable and safe to display; never a stack trace, SQL fragment, or internal path — error bodies reach browser consoles, client logs, and screenshots, making them the most-leaked surface of an API.
- `details` is optional, for field-level validation errors — it lets a form highlight the exact broken field instead of showing one generic banner.

### Pagination, filtering, sorting

- **Cursor pagination is the default**: `GET /invoices?limit=50&cursor=abc123`. Offset pagination breaks under concurrent writes (rows shift between pages, so items duplicate or vanish) and `OFFSET 100000` still scans the skipped rows; cursors are stable and O(page). Offset is acceptable only for small, effectively static datasets.
- List responses use an envelope:

```json
{ "data": [], "nextCursor": "abc123" }
```

  A bare JSON array cannot grow metadata later — adding `nextCursor` to an array response is a breaking change, while adding a field to an envelope is not.

- `nextCursor` is `null` (or absent) on the last page; cursors are opaque to clients — opacity is what lets you change the underlying scheme (keyset, snapshot token) without breaking anyone.
- Filters are query parameters named after fields: `?status=paid&customerId=cus_1`.
- Sorting: `?sort=-createdAt` (leading `-` for descending); document which fields are sortable — every sortable field is an index commitment, so the set is a contract, not a free-for-all.

### Versioning

- Version in the path: `/v1/invoices`. Every API starts at `v1` — no unversioned routes, because the moment an unversioned route has one external consumer, you can never change it safely.
- **Additive changes do not bump the version** (new fields, new endpoints, new optional params). Clients must ignore unknown response fields — this tolerant-reader rule is what lets the API evolve weekly without a version explosion.
- Breaking changes (removing/renaming fields, changing types or semantics) require a new version and a deprecation window during which both run — consumers plan around deadlines, not surprises; an overnight break teaches them to never upgrade again.

## GraphQL

For client-driven aggregation — many frontends selecting different slices of the same graph. The flexibility clients gain is complexity the server inherits; these rules keep it bounded.

- **One graph per product**, schema-first, every type and field carrying a description — the schema is the API documentation; an undescribed field is an undocumented endpoint.
- Naming: `camelCase` fields, `PascalCase` types, past-tense mutation payloads (`InvoicePaidPayload`) — mirrors the JSON field conventions below so REST and GraphQL payloads look like one family.
- **Resolvers must batch** (dataloader pattern) — naive per-field resolvers turn one query into N+1 backend calls, and a nested query turns quadratic; batching is not an optimization, it is the difference between a working and a collapsing graph.
- **Depth and complexity limits + mandatory pagination on list fields** — clients compose queries you never wrote, so an unbounded graph is a denial-of-service endpoint you built yourself. Use cursor-style connections for lists.
- Errors: transport/system failures go in the top-level `errors` array; **domain failures are typed results in the schema** (`union PayInvoiceResult = Invoice | InvoiceNotFound`) — clients can exhaustively match schema errors, while parsing `errors[].message` strings is the GraphQL version of the string-matching trap.
- **No breaking schema changes**: deprecate with `@deprecated(reason: "...")`, remove after a published window — the schema registry (or `graphql-inspector` in CI) enforces this the way `buf breaking` does for protos.
- Persisted queries for public/browser clients — they shrink payloads and turn "any query anyone invents" into an allow-list, closing the complexity-attack surface.

## gRPC

For service-to-service calls where typed contracts, low latency, or streaming matter. Protos are the contract — treat them with migration-level care.

- Proto style follows [buf](https://buf.build/) defaults; `buf lint` and `buf breaking` run in CI — automated breaking-change detection is the single biggest reason to use protos, so a repo without `buf breaking` is carrying the cost and skipping the benefit.
- Package versioning: `thebigtechplus.billing.v1` — the version lives in the package so v1 and v2 coexist in one binary during migration.
- **Every call sets a deadline and propagates it** — a call without a deadline waits forever on a dead peer, and one hung dependency cascades into a thread-pool-exhaustion outage upstream. Deadlines shrink as they propagate; work that outlives its caller's deadline is wasted by definition.
- Retries only on idempotent RPCs, with exponential backoff and a retry budget — blind retries on non-idempotent calls double-charge, and unbudgeted retries turn a partial outage into a total one (retry storms).
- Use the canonical status codes (`NOT_FOUND`, `INVALID_ARGUMENT`, `ALREADY_EXISTS`, `UNAVAILABLE`, ...) consistently with the HTTP table above — middleware, dashboards, and clients branch on codes; inventing your own mapping breaks all three.
- Streaming for large transfers and live feeds; unary otherwise — streams hold connection state and complicate load balancing, so they must earn their keep.

## WebSockets and SSE

For pushing data to clients. **Prefer SSE for one-way push** — it is plain HTTP, so auth, proxies, HTTP/2 multiplexing, and automatic reconnect with `Last-Event-ID` resume all come free; WebSockets are for genuinely bidirectional exchange, where you take on connection management yourself.

- Message envelope mirrors webhooks: `{ "id", "type", "data" }` — a consumer that handles your webhooks can handle your stream, and `id` is what makes resume-after-disconnect possible.
- Authenticate at connection time and re-authorize sensitive actions in-stream — a connection can outlive its token by hours, and "authenticated once at connect" quietly becomes "authorized forever".
- Heartbeat/ping on an interval and drop idle connections — half-open TCP connections look alive for minutes after the peer vanished; without heartbeats you are broadcasting to ghosts and leaking connection slots.
- Clients reconnect with **jittered** exponential backoff and a resume cursor (`Last-Event-ID` or your own) — synchronized reconnects after a blip are a thundering herd that turns a 5-second network hiccup into a self-inflicted outage.
- Don't push large payloads over the stream; push the event and let the client fetch details via the API — streams multiply every byte by the connection count, and a fat message stalls everything behind it on that connection.

## Events and queues

For decoupled, asynchronous workflows between services. The producer states facts; consumers decide what to do with them.

- Event names are past-tense facts, `entity.verb`: `invoice.paid`, `user.registered` — an event records something that happened; if you are telling a specific consumer what to *do*, that is a command (a different contract) and naming it like an event misleads every future subscriber.
- Envelope: `{ "id", "type", "occurredAt", "data" }`, following the same field conventions as JSON APIs — consumers already know how to read timestamps and IDs, and `id` enables deduplication.
- **Delivery is at-least-once; consumers are idempotent by event `id`** — exactly-once over an unreliable network is a myth, so duplicates are a feature of honest delivery; a consumer that cannot tolerate replays is a consumer with a latent double-processing bug.
- Schema evolution is additive-only; breaking changes mean a new event type or version (`invoice.paid.v2`) — you do not control when consumers deploy, so a changed payload breaks them at *your* release time, not theirs.
- **Dead-letter queues exist and are monitored** — an unmonitored DLQ is silent data loss with a delay; every message there is a customer action that never took effect.
- Queues are buffers, not databases — retention absorbs downtime and spikes; the moment a consumer relies on replaying history as its source of truth, you have an accidental (and worse) database.

## Field conventions

These apply to every JSON payload — REST bodies, GraphQL responses, stream messages, event envelopes:

- JSON fields are **camelCase** — one convention org-wide, chosen to match the JavaScript/TypeScript consumers who read these payloads verbatim.
- Timestamps are **RFC 3339 UTC** strings, suffixed `At`: `createdAt`, `expiresAt` — RFC 3339 is unambiguous, sortable as a string, and parseable in every language; epoch integers force every reader to guess seconds vs milliseconds.
- IDs are strings (even when numeric today), ideally prefixed: `inv_8fk2...` — numeric IDs silently lose precision above 2^53 in JavaScript, advertise your row count, and invite enumeration; prefixed strings also make an ID self-identifying in a log line.
- Booleans are `true`/`false`, named as predicates: `isPaid`, `hasAttachments` — never `0`/`1`, which force every consumer to remember a private truthiness convention.
- Money is integer minor units plus an ISO 4217 currency: `{ "amount": 10990, "currency": "MMK" }` — never floats: `0.1 + 0.2 !== 0.3` in binary floating point, and accounting bugs of a cent at a time are the hardest class to detect and the worst to explain.
- Enum values are lowercase strings; document the full set and treat unknown values as an error — silently ignoring an unknown status means a client keeps showing "pending" for a state invented after it shipped.

## Authentication and authorization

- Bearer tokens in the `Authorization` header: `Authorization: Bearer <token>`. In gRPC, the same token travels in call metadata; on WebSocket/SSE, authenticate at connect (see above).
- Never put tokens or API keys in URLs — URLs are logged by every proxy and access log on the path, saved in browser history, and leaked wholesale via the `Referer` header.
- 401 for missing/invalid credentials; 403 for valid credentials without permission — the distinction tells the client whether to re-authenticate (401) or stop asking (403). Use 404 when acknowledging a resource's existence would itself leak information: a 403 on `/users/12345` confirms user 12345 exists.

## Idempotency

- Operations with side effects that clients retry (payments, sends, provisioning) accept an `Idempotency-Key` header (REST) or a client-supplied request ID (gRPC, events) — networks fail *after* the server acted as often as before, so a client that never got the response must be able to retry without double-charging anyone.
- Same key + same body → return the original result; same key + different body → 409 (the client is confused, and guessing which request they meant is worse than telling them).
- Keys expire after a documented window (24h is a sane default) — storing them forever is unbounded state for requests nobody will ever retry again.

## Webhooks

The outbound flavor of events: the same envelope and idempotency physics as [Events and queues](#events-and-queues), delivered over HTTP to URLs you do not control.

- Sign payloads (HMAC in a header) so consumers can verify origin — a webhook endpoint is a public URL that anyone can POST to; without a signature, an attacker can forge "payment succeeded" events. Document the scheme.
- Deliver at-least-once with exponential backoff; consumers must be idempotent (use the event `id`) — exactly-once delivery over an unreliable network is a myth, so duplicates are a *feature* of honest delivery, and consumers must expect them.
- Webhook bodies follow the same field conventions as the API; include `id`, `type`, `createdAt`, and a `data` object — `type` lets one endpoint route many event kinds, and `id` is what makes consumer-side deduplication possible.
