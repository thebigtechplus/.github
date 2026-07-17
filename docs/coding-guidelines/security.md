# Security engineering

Day-to-day security rules for building BigTech+ software. Reporting a vulnerability is separate — follow [SECURITY.md](../../SECURITY.md). Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

## Input

- **All external input is validated at the boundary** before it reaches domain code — HTTP bodies, query params, headers, queue messages, file uploads, environment variables. Use the stack's validator (zod, pydantic, serde + validation, hand-rolled in Go) per the language guides.
- Validate allow-list style (what is permitted), not deny-list (what is forbidden).
- Uploaded files: check size and content type server-side; never trust the filename; store outside the web root under a generated name.

## Authentication and authorization

- Authenticate at the edge (middleware); **authorize per resource in the service layer** — route-level checks alone are not enough.
- Deny by default: no permission match means 403, not fall-through.
- Sessions/tokens: short-lived access tokens, server-side revocation for long-lived ones, `HttpOnly`/`Secure`/`SameSite` on cookies.
- Never roll your own password handling: argon2id or bcrypt via a maintained library; never MD5/SHA for passwords; never reversible encryption for them.

## Secrets

- Secrets come from the environment or a secret manager — never source code, config files in git, logs, or error messages. gitleaks runs in pre-commit; treat a leaked secret as compromised and rotate it, then report per [SECURITY.md](../../SECURITY.md).
- Different secrets per environment; production secrets are visible to the fewest possible people.

## Dependencies

- Lockfiles are committed; upgrades are deliberate PRs, not side effects.
- Audit in CI: `govulncheck` (Go), `pip-audit`/`uv` (Python), `pnpm audit`/`bun audit` (TypeScript), `cargo audit` (Rust).
- Enable Dependabot ([docs/new-repo.md](../new-repo.md) step 5); merge security bumps promptly.
- New dependencies are a review point: prefer the standard library; a package that saves ten lines is not worth a supply-chain edge.

## HTTP

- TLS everywhere, including service-to-service.
- CORS is an explicit allow-list of origins; never `*` together with credentials.
- Rate-limit public endpoints (return 429 + `Retry-After`, see [api-design.md](api-design.md)); stricter limits on auth endpoints.
- Set the standard headers on web responses: `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `Content-Security-Policy` where HTML is served.

## Data

- Minimize PII: collect what the feature needs, nothing more; know which tables hold it ([database.md](database.md)).
- No sensitive data (tokens, passwords, full card numbers, personal data) in logs, traces, or analytics — structured logging makes redaction enforceable.
- Encrypt sensitive data at rest where the platform offers it; application-level encryption only with a reviewed design.
