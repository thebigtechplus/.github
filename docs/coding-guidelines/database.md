# Database and migrations

Rules for relational schemas and data access in BigTech+ services. The schema outlives every application rewrite — data mistakes compound daily and are the most expensive class to fix, which is why these rules are stricter than code style. Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

## Naming

- Tables and columns are `snake_case`; tables are **plural** (`invoices`, `payment_methods`) — SQL is case-insensitive by default, so camelCase either collapses to lowercase or forces quoted identifiers everywhere, forever.
- Primary key is `id`. Foreign keys are `<entity>_id` (`customer_id`) — with one convention, every join is guessable without opening the schema.
- Every table has `created_at` and `updated_at` (UTC) — the first question in every production investigation is "when did this row change?", and you cannot add history retroactively.
- Indexes and constraints are named, not auto-generated: `idx_invoices_customer_id`, `fk_invoices_customer` — auto-generated names differ per environment, which makes migrations that alter or drop them non-portable, and turns error messages into riddles.

## Migrations

- **Forward-only.** Roll forward with a new migration; down-migrations are optional and untrusted in production — a down that drops a column destroys the data written since the up ran, so "rollback" is usually a lie. Practicing roll-forward means your incident response uses the path you exercise daily.
- One logical change per migration; migrations are reviewed like code — they *are* code, with a blast radius bigger than most: a bad merge is revertible, a bad `DROP` is not.
- **Never edit a migration that has been applied anywhere** — write a new one. Environments that already ran the original will silently diverge from environments that run the edited version; the entire point of migrations is that every database reaches the same state by the same steps.
- Schema changes on live tables must be deploy-safe: additive first (add column nullable → backfill → add constraint), destructive last, never in the same release that stops using the thing — during a rolling deploy, old code and new schema run side by side, and the old code must keep working against it. Renaming a column in one step is an outage.
- Tooling per stack — goose/atlas (Go), alembic (Python), drizzle-kit (TypeScript), sqlx/refinery (Rust). Pick one per project and stay with it; migrations live in the repo so schema history travels with code history in the same PRs.

## Queries

- **Parameterized queries always.** String-built SQL is banned — no exceptions, including "it's internal". Injection is still the most exploited vulnerability class in the wild; one forgotten escape in five years of commits is all it takes, and parameterization removes the entire bug class instead of relying on eternal discipline. ("Internal" services stop being internal the day someone adds a webhook.)
- Add the index in the same PR as the query that needs it; explain the access pattern in the PR description — an unindexed query works fine on the ten rows in staging and melts at the first hundred thousand in production; the review is the only moment someone is actually looking.
- `SELECT` the columns you use, not `*`, in application code — `*` silently changes shape when someone adds a column, breaking positional reads and dragging large blobs across the wire that nobody asked for.
- N+1 query patterns are a review blocker; batch or join instead — one query per row works in the demo and produces a thousand round trips on the first real page load; it is the single most common cause of "the app got slow".

## Transactions

- Keep transactions short; no network calls, no external API requests inside one — a transaction holds locks, and every millisecond you hold them is a millisecond every contending query waits. An external call inside a transaction ties your lock time to someone else's latency and outage.
- Wrap multi-statement invariants in a transaction — don't rely on "it usually runs fast enough"; the crash between statement one and statement two *will* eventually happen, and half-applied invariants are the corruption nobody notices for months.
- Set explicit isolation when correctness depends on it, and comment why — the default level differs per database, and a reader cannot distinguish "the default is fine here" from "the author never thought about it" unless you tell them.

## Data

- Timestamps stored in UTC (`timestamptz` in Postgres); conversion happens at the display edge — the moment two writers use different zones, every comparison, sort, and DST boundary in the table is quietly wrong.
- Soft-delete (`deleted_at`) only when there is a real recovery or audit requirement — otherwise delete. Soft-delete taxes every query in the system with a `WHERE deleted_at IS NULL` that someone will forget, resurrecting "deleted" data in a report or an email list. Whichever you use, filters must be consistent everywhere.
- Don't put data you filter or join on into JSON columns; JSON is for genuinely schemaless payloads — JSON fields dodge type checking, foreign keys, and (mostly) indexes; "we'll query it later" later means a migration under pressure.
- PII gets an inventory comment in the schema and minimal replication into logs, analytics, and backups (see [security.md](security.md)) — you cannot honor a deletion request for data you cannot find, and every copy is another breach surface.
