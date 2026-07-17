# API design

Contract rules for all BigTech+ HTTP/JSON APIs, in every language. Cross-language rules: [coding-guidelines.md](../coding-guidelines.md); language specifics: the per-language guides.

## Resources and URLs

- Resources are **plural nouns**: `/invoices`, `/invoices/{id}`, `/users/{id}/sessions`.
- Path segments are **kebab-case** (`/payment-methods`), path parameters `{camelCase}`.
- Nest at most one level deep. If you need `/a/{id}/b/{id}/c`, promote `c` to a top-level resource with a filter (`/c?bId=`).
- No verbs in URLs. When an operation truly isn't CRUD, model it as a sub-resource action: `POST /invoices/{id}/send`.

## Methods

| Method | Use | Properties |
| --- | --- | --- |
| GET | Read | Safe, idempotent, cacheable — never mutates |
| POST | Create a resource; actions | Not idempotent (unless idempotency key) |
| PUT | Full replace | Idempotent |
| PATCH | Partial update | Send only changed fields |
| DELETE | Remove | Idempotent — deleting twice is not an error surface, return 404 or 204 consistently |

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

- `code` is machine-readable `SCREAMING_SNAKE`, stable across releases — clients branch on it.
- `message` is human-readable and safe to display; never a stack trace, SQL fragment, or internal path.
- `details` is optional, for field-level validation errors.

## Field conventions

- JSON fields are **camelCase**.
- Timestamps are **RFC 3339 UTC** strings, suffixed `At`: `createdAt`, `expiresAt`.
- IDs are strings (even when numeric today), ideally prefixed: `inv_8fk2...`.
- Booleans are `true`/`false`, named as predicates: `isPaid`, `hasAttachments` — never `0`/`1`.
- Money is integer minor units plus an ISO 4217 currency: `{ "amount": 10990, "currency": "MMK" }` — never floats.
- Enum values are lowercase strings; document the full set and treat unknown values as an error.

## Pagination, filtering, sorting

- **Cursor pagination is the default**: `GET /invoices?limit=50&cursor=abc123`. Offset pagination only for small, stable datasets.
- List responses use an envelope:

```json
{ "data": [], "nextCursor": "abc123" }
```

- `nextCursor` is `null` (or absent) on the last page; cursors are opaque to clients.
- Filters are query parameters named after fields: `?status=paid&customerId=cus_1`.
- Sorting: `?sort=-createdAt` (leading `-` for descending); document which fields are sortable.

## Versioning

- Version in the path: `/v1/invoices`. Every API starts at `v1` — no unversioned routes.
- **Additive changes do not bump the version** (new fields, new endpoints, new optional params). Clients must ignore unknown response fields.
- Breaking changes (removing/renaming fields, changing types or semantics) require a new version and a deprecation window during which both run.

## Authentication and authorization

- Bearer tokens in the `Authorization` header: `Authorization: Bearer <token>`.
- Never put tokens or API keys in URLs — they end up in logs and browser history.
- 401 for missing/invalid credentials; 403 for valid credentials without permission; 404 when acknowledging a resource's existence would itself leak information.

## Idempotency

- Endpoints with side effects that clients retry (payments, sends, provisioning) accept an `Idempotency-Key` header.
- Same key + same body → return the original result; same key + different body → 409.
- Keys expire after a documented window (24h is a sane default).

## Webhooks

- Sign payloads (HMAC in a header) so consumers can verify origin; document the scheme.
- Deliver at-least-once with exponential backoff; consumers must be idempotent (use the event `id`).
- Webhook bodies follow the same field conventions as the API; include `id`, `type`, `createdAt`, and a `data` object.
