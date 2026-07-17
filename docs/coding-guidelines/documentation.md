# Documentation and comments

How BigTech+ code explains itself — comments, in-code documentation (doc comments), READMEs, and architecture decision records. Documentation is how knowledge survives contact with time and turnover — the author of any given line is, statistically, gone or forgetful by the time it matters. Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

## Comments

- Comments explain **why**, not what — constraints, trade-offs, and links to the decision, not a prose rerun of the next line. The code already says what it does; only the author knows why it does it *this* way, and that knowledge evaporates the day they move on. A "what" comment is worse than none: it duplicates the code and drifts out of sync with it.
- Delete commented-out code; git remembers it — while the block sits there it misleads every reader about what actually runs, and after two refactors nobody remembers whether it is safe to delete, so it becomes permanent noise.
- `TODO`s carry an issue number: `TODO(#123): remove after v2 migration`. A TODO without an issue is a wish, not a plan — it has no owner, no deadline, and grep will find it untouched five years from now.
- When a comment and its code disagree, that's a bug — fix both in the same commit; a reader cannot tell which one is lying, so a stale comment actively sabotages the debugging it was meant to help.

## In-code documentation

Public APIs get doc comments in the language's native format — godoc (Go), docstrings (Python), TSDoc (TypeScript), rustdoc (Rust). Native formats surface in editor hover, generated docs, and `cargo doc`/`go doc` — the same words reach every consumer without anyone maintaining a separate site.

### What to document

- **Every exported/public symbol gets a doc comment**; internal code only where intent is non-obvious — the public surface is read by people who cannot see (or should not need to read) the implementation.
- Document what the signature cannot say: behavior, parameter constraints ("must be positive", "UTC only"), error/exception conditions, side effects, and concurrency expectations ("safe for concurrent use") — these are exactly the things callers otherwise discover in production.
- **The first sentence stands alone** — tooling shows it in symbol lists and hover popups, so it must summarize without the rest. Go and Rust convention: start with the symbol name ("ParseInvoice parses...").
- Include a short usage example for non-trivial APIs — examples are the most-read part of any documentation, and in Go (`Example` test functions) and Rust (rustdoc code blocks) they compile and run as tests, so they cannot rot.
- Never restate the signature — `// GetInvoice gets an invoice` teaches nothing and trains readers to skip all doc comments, including the ones that matter.
- Update the doc comment in the same change as the behavior — same-PR rule as every other doc.

### Go — godoc

```go
// ParseInvoice parses raw invoice JSON into an Invoice.
//
// The payload must use minor currency units (see api-design.md).
// It returns ErrMalformed if the JSON does not match the invoice
// schema, and ErrUnsupportedCurrency for currencies outside ISO 4217.
func ParseInvoice(data []byte) (Invoice, error)
```

Package-level docs go in a comment above `package billing` in the package's main file; runnable `func ExampleParseInvoice()` tests double as documentation.

### Python — Google-style docstrings

```python
def parse_invoice(data: bytes) -> Invoice:
    """Parse raw invoice JSON into an Invoice.

    The payload must use minor currency units (see api-design.md).

    Args:
        data: UTF-8 encoded JSON matching the invoice schema.

    Returns:
        The parsed invoice with amounts in minor units.

    Raises:
        MalformedInvoiceError: If the JSON does not match the schema.
        UnsupportedCurrencyError: If the currency is not ISO 4217.
    """
```

Google style matches our adopted Python guide; ruff's `pydocstyle` rules can enforce presence and format.

### TypeScript — TSDoc

```typescript
/**
 * Parses raw invoice JSON into an {@link Invoice}.
 *
 * The payload must use minor currency units (see api-design.md).
 *
 * @param data - UTF-8 encoded JSON matching the invoice schema.
 * @returns The parsed invoice with amounts in minor units.
 * @throws {MalformedInvoiceError} If the JSON does not match the schema.
 */
export function parseInvoice(data: Uint8Array): Invoice
```

Editors surface TSDoc on hover at every call site — the doc travels with autocomplete.

### Rust — rustdoc

```rust
/// Parses raw invoice JSON into an [`Invoice`].
///
/// The payload must use minor currency units (see api-design.md).
///
/// # Errors
///
/// Returns [`InvoiceError::Malformed`] if the JSON does not match the
/// schema, and [`InvoiceError::UnsupportedCurrency`] for currencies
/// outside ISO 4217.
///
/// # Examples
///
/// ```
/// let invoice = billing::parse_invoice(br#"{"id":"inv_1"}"#)?;
/// ```
pub fn parse_invoice(data: &[u8]) -> Result<Invoice, InvoiceError>
```

Rustdoc examples are compiled and executed by `cargo test` — documentation that cannot lie.

## READMEs

Every repository's README answers, near the top:

1. What this is and who it's for
2. How to run it locally (setup, commands)
3. How to test it

The README is the front door: every new teammate, on-call responder, and future-you arrives there first, usually in a hurry. A repo that takes an afternoon of Slack archaeology to run is a repo with a bus factor of one. The [seeded template](../../scripts/templates/README.md) provides the structure — fill it in, don't delete the sections.

## Architecture decision records

Significant, hard-to-reverse choices (framework, storage engine, protocol, service split) get an ADR in the repo at `docs/adr/NNN-short-title.md`. The payoff comes eighteen months later, when someone asks "why is this cursor-paginated?" — without the record, teams either cargo-cult the old decision ("it must have had a reason") or re-litigate it from scratch; with it, they can check whether the original constraints still hold:

```markdown
# 001 — Use cursor pagination for all list endpoints

## Status
Accepted (2026-07-17)

## Context
Offset pagination degrades on large tables and breaks under concurrent writes...

## Decision
All list endpoints use cursor pagination per api-design.md.

## Consequences
Clients cannot jump to page N; sorting fields must be indexed...
```

ADRs are immutable history: supersede with a new record, don't rewrite an accepted one — an edited record erases what the team believed at the time, which is exactly the information the next reader needs to judge whether circumstances have changed.

## Keeping docs honest

- Docs live next to the code they describe and **change in the same PR** as the behavior — a doc-only follow-up "later" never happens; the PR is the only moment when updating the doc costs one minute instead of an investigation.
- Reviewers treat stale docs like failing tests ([reviews.md](reviews.md)) — a wrong doc is worse than a missing one, because readers trust it.
- Prefer executable documentation — examples that run in tests, `--help` output, schema files — over prose that can drift: documentation that is executed cannot lie, because CI fails the moment it does.
