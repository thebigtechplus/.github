# Database and migrations

Rules for relational schemas and data access in BigTech+ services. Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

## Naming

- Tables and columns are `snake_case`; tables are **plural** (`invoices`, `payment_methods`).
- Primary key is `id`. Foreign keys are `<entity>_id` (`customer_id`).
- Every table has `created_at` and `updated_at` (UTC).
- Indexes and constraints are named, not auto-generated: `idx_invoices_customer_id`, `fk_invoices_customer`.

## Migrations

- **Forward-only.** Roll forward with a new migration; down-migrations are optional and untrusted in production.
- One logical change per migration; migrations are reviewed like code — they *are* code.
- **Never edit a migration that has been applied anywhere** — write a new one.
- Schema changes on live tables must be deploy-safe: additive first (add column nullable → backfill → add constraint), destructive last, never in the same release that stops using the thing.
- Tooling per stack — goose/atlas (Go), alembic (Python), drizzle-kit (TypeScript), sqlx/refinery (Rust). Pick one per project and stay with it; migrations live in the repo.

## Queries

- **Parameterized queries always.** String-built SQL is banned — no exceptions, including "it's internal".
- Add the index in the same PR as the query that needs it; explain the access pattern in the PR description.
- `SELECT` the columns you use, not `*`, in application code.
- N+1 query patterns are a review blocker; batch or join instead.

## Transactions

- Keep transactions short; no network calls, no external API requests inside one.
- Wrap multi-statement invariants in a transaction — don't rely on "it usually runs fast enough".
- Set explicit isolation when correctness depends on it, and comment why.

## Data

- Timestamps stored in UTC (`timestamptz` in Postgres); conversion happens at the display edge.
- Soft-delete (`deleted_at`) only when there is a real recovery or audit requirement — otherwise delete. Whichever you use, filters must be consistent everywhere.
- Don't put data you filter or join on into JSON columns; JSON is for genuinely schemaless payloads.
- PII gets an inventory comment in the schema and minimal replication into logs, analytics, and backups (see [security.md](security.md)).
