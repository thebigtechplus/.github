# API design

Contract rules for all BigTech+ HTTP/JSON APIs, in every language. One org-wide contract means a developer who has integrated one of our APIs already knows how the next one paginates, errors, and versions — that predictability is the entire value of these rules. Cross-language rules: [coding-guidelines.md](../coding-guidelines.md); language specifics: the per-language guides.

## Resources and URLs

- Resources are **plural nouns**: `/invoices`, `/invoices/{id}`, `/users/{id}/sessions` — consistent plurals mean nobody ever guesses wrong between `/invoice/42` and `/invoices/42`.
- Path segments are **kebab-case** (`/payment-methods`), path parameters `{camelCase}` — URLs are case-sensitive and get retyped from logs and docs; lowercase-with-dashes survives that round trip.
- Nest at most one level deep. If you need `/a/{id}/b/{id}/c`, promote `c` to a top-level resource with a filter (`/c?bId=`) — deep nesting forces clients to carry every ancestor ID to address a resource that has its own identity anyway.
- No verbs in URLs — the method *is* the verb; `POST /invoices/create` says create twice and eventually disagrees with itself. When an operation truly isn't CRUD, model it as a sub-resource action: `POST /invoices/{id}/send`.

## Methods

| Method | Use | Properties |
| --- | --- | --- |
| GET | Read | Safe, idempotent, cacheable — never mutates |
| POST | Create a resource; actions | Not idempotent (unless idempotency key) |
| PUT | Full replace | Idempotent |
| PATCH | Partial update | Send only changed fields |
| DELETE | Remove | Idempotent — deleting twice is not an error surface, return 404 or 204 consistently |

These properties are not etiquette — infrastructure acts on them. Proxies and browsers cache GETs and retry idempotent methods; a GET that mutates will be prefetched by a crawler, and a non-idempotent PUT breaks every retry layer between the client and you.

## Status codes

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

## Error format

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

## Field conventions

- JSON fields are **camelCase** — one convention org-wide, chosen to match the JavaScript/TypeScript consumers who read these payloads verbatim.
- Timestamps are **RFC 3339 UTC** strings, suffixed `At`: `createdAt`, `expiresAt` — RFC 3339 is unambiguous, sortable as a string, and parseable in every language; epoch integers force every reader to guess seconds vs milliseconds.
- IDs are strings (even when numeric today), ideally prefixed: `inv_8fk2...` — numeric IDs silently lose precision above 2^53 in JavaScript, advertise your row count, and invite enumeration; prefixed strings also make an ID self-identifying in a log line.
- Booleans are `true`/`false`, named as predicates: `isPaid`, `hasAttachments` — never `0`/`1`, which force every consumer to remember a private truthiness convention.
- Money is integer minor units plus an ISO 4217 currency: `{ "amount": 10990, "currency": "MMK" }` — never floats: `0.1 + 0.2 !== 0.3` in binary floating point, and accounting bugs of a cent at a time are the hardest class to detect and the worst to explain.
- Enum values are lowercase strings; document the full set and treat unknown values as an error — silently ignoring an unknown status means a client keeps showing "pending" for a state invented after it shipped.

## Pagination, filtering, sorting

- **Cursor pagination is the default**: `GET /invoices?limit=50&cursor=abc123`. Offset pagination breaks under concurrent writes (rows shift between pages, so items duplicate or vanish) and `OFFSET 100000` still scans the skipped rows; cursors are stable and O(page). Offset is acceptable only for small, effectively static datasets.
- List responses use an envelope:

```json
{ "data": [], "nextCursor": "abc123" }
```

  A bare JSON array cannot grow metadata later — adding `nextCursor` to an array response is a breaking change, while adding a field to an envelope is not.

- `nextCursor` is `null` (or absent) on the last page; cursors are opaque to clients — opacity is what lets you change the underlying scheme (keyset, snapshot token) without breaking anyone.
- Filters are query parameters named after fields: `?status=paid&customerId=cus_1`.
- Sorting: `?sort=-createdAt` (leading `-` for descending); document which fields are sortable — every sortable field is an index commitment, so the set is a contract, not a free-for-all.

## Versioning

- Version in the path: `/v1/invoices`. Every API starts at `v1` — no unversioned routes, because the moment an unversioned route has one external consumer, you can never change it safely.
- **Additive changes do not bump the version** (new fields, new endpoints, new optional params). Clients must ignore unknown response fields — this tolerant-reader rule is what lets the API evolve weekly without a version explosion.
- Breaking changes (removing/renaming fields, changing types or semantics) require a new version and a deprecation window during which both run — consumers plan around deadlines, not surprises; an overnight break teaches them to never upgrade again.

## Authentication and authorization

- Bearer tokens in the `Authorization` header: `Authorization: Bearer <token>`.
- Never put tokens or API keys in URLs — URLs are logged by every proxy and access log on the path, saved in browser history, and leaked wholesale via the `Referer` header.
- 401 for missing/invalid credentials; 403 for valid credentials without permission — the distinction tells the client whether to re-authenticate (401) or stop asking (403). Use 404 when acknowledging a resource's existence would itself leak information: a 403 on `/users/12345` confirms user 12345 exists.

## Idempotency

- Endpoints with side effects that clients retry (payments, sends, provisioning) accept an `Idempotency-Key` header — networks fail *after* the server acted as often as before, so a client that never got the response must be able to retry without double-charging anyone.
- Same key + same body → return the original result; same key + different body → 409 (the client is confused, and guessing which request they meant is worse than telling them).
- Keys expire after a documented window (24h is a sane default) — storing them forever is unbounded state for requests nobody will ever retry again.

## Webhooks

- Sign payloads (HMAC in a header) so consumers can verify origin — a webhook endpoint is a public URL that anyone can POST to; without a signature, an attacker can forge "payment succeeded" events. Document the scheme.
- Deliver at-least-once with exponential backoff; consumers must be idempotent (use the event `id`) — exactly-once delivery over an unreliable network is a myth, so duplicates are a *feature* of honest delivery, and consumers must expect them.
- Webhook bodies follow the same field conventions as the API; include `id`, `type`, `createdAt`, and a `data` object — `type` lets one endpoint route many event kinds, and `id` is what makes consumer-side deduplication possible.
