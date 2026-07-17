# Security engineering

Day-to-day security rules for building BigTech+ software. Security is an engineering habit, not an audit event — every rule here exists because skipping it has burned real companies. Reporting a vulnerability is separate — follow [SECURITY.md](../../SECURITY.md). Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

## Input

- **All external input is validated at the boundary** before it reaches domain code — HTTP bodies, query params, headers, queue messages, file uploads, environment variables. Every injection, overflow, and deserialization exploit begins as input someone trusted; validating at the boundary means the entire interior of the system can trust its data, instead of every function defensively re-checking. Use the stack's validator (zod, pydantic, serde + validation, hand-rolled in Go) per the language guides.
- Validate allow-list style (what is permitted), not deny-list (what is forbidden) — a deny-list is a bet that you can enumerate every attack that will ever be invented; attackers only need the one encoding trick you missed.
- Uploaded files: check size and content type server-side; never trust the filename — `../../etc/cron.d/job` is a filename, and path traversal via upload names is a classic. Store outside the web root under a generated name, so an uploaded `.html` or script can never be served back and executed on your origin.

## Authentication and authorization

- Authenticate at the edge (middleware); **authorize per resource in the service layer** — route-level checks alone produce IDOR bugs: the user is logged in, so `/invoices/42` happily serves someone else's invoice 42. "Is this user allowed to touch *this object*" is a domain question and must live with the domain logic.
- Deny by default: no permission match means 403, not fall-through — a fall-through default turns every forgotten rule into silent access; deny-by-default turns it into a bug report you fix in a day.
- Sessions/tokens: short-lived access tokens (a stolen token that expires in minutes is an incident; one that lives for a year is a breach), server-side revocation for long-lived ones, `HttpOnly`/`Secure`/`SameSite` on cookies — `HttpOnly` keeps XSS from reading the session, `Secure` keeps it off plaintext hops, `SameSite` blunts CSRF.
- Never roll your own password handling: argon2id or bcrypt via a maintained library — these are deliberately slow and memory-hard, which is the entire defense against offline cracking of a dumped table. Fast hashes (MD5/SHA) let commodity GPUs try billions of guesses per second, and reversible encryption means whoever holds the key holds every password.

## Secrets

- Secrets come from the environment or a secret manager — never source code, config files in git, logs, or error messages. Git history is forever: a secret committed once is in every clone and fork, and deleting the file does not delete the history. gitleaks runs in pre-commit; treat a leaked secret as compromised the moment it leaks (bots scrape public commits within minutes), rotate it, then report per [SECURITY.md](../../SECURITY.md).
- Different secrets per environment — shared secrets mean a staging compromise *is* a production compromise, and staging is always the softer target. Production secrets are visible to the fewest possible people: every additional holder is another phishing target.

## Dependencies

- Lockfiles are committed; upgrades are deliberate PRs, not side effects — an unlocked dependency tree means any upstream release (or hijacked package) walks straight into your next build unreviewed.
- Audit in CI: `govulncheck` (Go), `pip-audit`/`uv` (Python), `pnpm audit`/`bun audit` (TypeScript), `cargo audit` (Rust) — known CVEs are the attacks that require zero skill; scanning in CI makes "we didn't know" impossible.
- Enable Dependabot ([docs/new-repo.md](../new-repo.md) step 5); merge security bumps promptly — the window between a CVE's publication and its mass exploitation is now measured in days.
- New dependencies are a review point: prefer the standard library; a package that saves ten lines is not worth a supply-chain edge — every dependency is code you run with full privileges, written by someone you have never met, updated on their schedule.

## HTTP

- TLS everywhere, including service-to-service — "internal" networks stop being trustworthy at the first compromised pod or misconfigured VPC peering; plaintext internal traffic hands an attacker with a foothold everything at once.
- CORS is an explicit allow-list of origins; never `*` together with credentials — that combination lets any website on the internet make authenticated requests as your logged-in users.
- Rate-limit public endpoints (return 429 + `Retry-After`, see [api-design.md](api-design.md)); stricter limits on auth endpoints — an unthrottled login endpoint is a free password-guessing oracle, and credential-stuffing lists are traded by the billion.
- Set the standard headers on web responses: `Strict-Transport-Security` (stops protocol-downgrade on the first visit), `X-Content-Type-Options: nosniff` (stops browsers "helpfully" executing a text upload as script), `Content-Security-Policy` where HTML is served (turns most XSS from exploitation into a console error).

## Data

- Minimize PII: collect what the feature needs, nothing more; know which tables hold it ([database.md](database.md)) — data you never stored cannot be breached, subpoenaed, or fined; every extra field is pure liability at breach time.
- No sensitive data (tokens, passwords, full card numbers, personal data) in logs, traces, or analytics — logs flow to third-party dashboards, broad-access search indexes, and long-retention backups, all with weaker controls than the database the data came from. Structured logging makes redaction enforceable per-field; prose logs make it a hope.
- Encrypt sensitive data at rest where the platform offers it; application-level encryption only with a reviewed design — platform encryption is one checkbox that specialists maintain; hand-rolled crypto fails in ways that look exactly like success (wrong mode, reused nonce, key beside the data) until the day it matters.
