# Documentation and comments

How BigTech+ code explains itself. Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

## Comments

- Comments explain **why**, not what — constraints, trade-offs, and links to the decision, not a prose rerun of the next line.
- Delete commented-out code; git remembers it.
- `TODO`s carry an issue number: `TODO(#123): remove after v2 migration`. A TODO without an issue is a wish, not a plan.
- When a comment and its code disagree, that's a bug — fix both in the same commit.

## Doc comments

Public APIs get doc comments in the language's native format — godoc (Go), docstrings (Python), TSDoc (TypeScript), rustdoc (Rust). State what the caller must know: behavior, error conditions, ownership/lifetime where relevant. Skip doc comments that only restate the signature.

## READMEs

Every repository's README answers, near the top:

1. What this is and who it's for
2. How to run it locally (setup, commands)
3. How to test it

The [seeded template](../../scripts/templates/README.md) provides the structure — fill it in, don't delete the sections.

## Architecture decision records

Significant, hard-to-reverse choices (framework, storage engine, protocol, service split) get an ADR in the repo at `docs/adr/NNN-short-title.md`:

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

ADRs are immutable history: supersede with a new record, don't rewrite an accepted one.

## Keeping docs honest

- Docs live next to the code they describe and **change in the same PR** as the behavior — a doc-only follow-up "later" never happens.
- Reviewers treat stale docs like failing tests ([reviews.md](reviews.md)).
- Prefer executable documentation — examples that run in tests, `--help` output, schema files — over prose that can drift.
