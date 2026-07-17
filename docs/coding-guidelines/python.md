# Python guidelines

Org addendum for Python. Baseline: [PEP 8](https://peps.python.org/pep-0008/) and the [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html). Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

## Tooling

- [ruff](https://docs.astral.sh/ruff/) for both formatting and linting — one fast tool replaces the black + isort + flake8 stack, so there is one config to maintain and no tool-vs-tool conflicts.
- [uv](https://docs.astral.sh/uv/) preferred for dependency and environment management; commit the lock file — without a lock, two machines installing "the same" project resolve different dependency trees, and "works on my machine" becomes literal.
- Strict type checking (`pyright` or `mypy --strict`) in CI — Python will happily pass a `str` where a `dict` was expected and fail at runtime in production; the type checker moves that failure to the PR.

```bash
ruff format .
ruff check .
pyright
pytest
```

`pyproject.toml` baseline:

```toml
[tool.ruff]
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM"]
```

## Project structure

```text
myservice/
├── pyproject.toml
├── uv.lock
├── src/
│   └── myservice/
│       ├── __init__.py      # public surface only
│       ├── billing/         # one subpackage per domain feature
│       │   ├── __init__.py
│       │   ├── invoice.py
│       │   └── service.py
│       ├── api/             # transport layer (FastAPI routers)
│       └── storage/         # persistence layer
└── tests/
    └── billing/
        └── test_invoice.py
```

- Always the `src/` layout — with a flat layout, `import myservice` silently picks up the local directory instead of the installed package, so tests pass locally while the shipped artifact is broken. `src/` makes that class of bug impossible.
- Packages by domain feature; no `utils.py` or `helpers.py` dumping grounds — they grow forever, import everything, and end up on both sides of every circular-import error.

## Naming

| Kind | Convention | Example |
| --- | --- | --- |
| Module / package | `snake_case`, short | `billing` |
| Function / variable | `snake_case` | `parse_invoice` |
| Class | `PascalCase` | `InvoiceService` |
| Constant | `UPPER_SNAKE` | `MAX_RETRIES` |
| Private | leading underscore | `_normalize` |
| Test | `test_<scenario>` | `test_parse_invoice_missing_total` |

## Error handling

- Raise specific exceptions; define a small domain exception hierarchy per package — callers can then catch exactly the failure they can handle (`InvoiceNotFound`) instead of fishing in a generic `ValueError` that fifty unrelated code paths also raise.
- Catch narrow: never bare `except:` — it swallows `KeyboardInterrupt`, `SystemExit`, typos (`NameError`), and every bug you have not imagined yet, turning crashes into silent corruption. Catch `Exception` only at process boundaries (request handler, worker loop) where it is logged and translated.
- Use context managers (`with`) for anything that must be released — exceptions skip your manual `close()` call; `with` guarantees cleanup on every exit path.

```python
class InvoiceError(Exception): ...
class InvoiceNotFound(InvoiceError): ...

def get_invoice(invoice_id: str) -> Invoice:
    row = repo.find(invoice_id)
    if row is None:
        raise InvoiceNotFound(invoice_id)
    return Invoice.from_row(row)
```

## Design patterns

- **Type hints are required on all public functions and methods.** They are checked documentation — unlike docstrings they cannot drift, and they let the type checker catch a wrong-argument bug before review even starts. Data shapes are `dataclass`es (internal) or pydantic models (validated boundaries), not loose dicts — a dict's shape lives only in the heads of people who have read every producer.
- **Protocols over abstract base classes** for interfaces; the consumer defines the protocol it needs. Protocols are structural — implementers do not need to import or even know about them — which keeps the dependency arrow pointing the right way and lets tests fake exactly the methods in use.
- **Dependency injection by parameter** — pass collaborators into constructors/functions. No module-level singletons doing I/O at import time: import-time side effects fire during test collection, crash tools that merely import your module, and make behavior depend on import order.
- Prefer plain functions and modules; introduce a class when there is state plus behavior, not before — a class with one method and no state is a function with extra ceremony.

```python
class InvoiceStore(Protocol):
    def find(self, invoice_id: str) -> Row | None: ...

def make_service(store: InvoiceStore) -> InvoiceService: ...
```

Anti-patterns: mutable default arguments (the default is created **once** at definition — every call shares the same list, a bug that surfaces far from its cause), `from x import *` (nobody, including the linter, can tell where a name came from), god modules, import-time side effects, `hasattr`/`isinstance` chains where a protocol or union type says the same thing checkably.

## Concurrency

- `asyncio` for I/O-bound concurrency only; CPU-bound work goes to a process pool or a worker service — the GIL means async buys nothing for computation, and a CPU-heavy coroutine starves every other task on the loop.
- Do not mix sync and async carelessly: a blocking call inside `async def` freezes the entire event loop — every request in flight, not just yours — for the duration. Use `asyncio.to_thread` when a sync call is unavoidable.
- One event loop, owned at the entry point; libraries never call `asyncio.run` — a library that owns the loop cannot be composed with any other async code in the process.

## APIs and services

API contract rules (URLs, status codes, errors, pagination): [api-design.md](api-design.md).

- [FastAPI](https://fastapi.tiangolo.com/) is the default for APIs and lightweight services; pydantic models validate all request/response bodies — validation at the edge means domain code never sees malformed data, and the OpenAPI schema falls out for free.
- [Django](https://www.djangoproject.com/) (with [Django REST Framework](https://www.django-rest-framework.org/) for APIs) for full-featured web applications — when you need admin, ORM, auth, and sessions, Django's integrated versions have twenty years of hardening that a hand-assembled equivalent will not reach. Follow Django's app structure: one app per domain feature, fat models/services, thin views.
- Routers/views stay thin: validate → call service → return model. No business logic in route functions — logic there can only be exercised through HTTP, which makes tests slow and couples rules to a transport.
- JSON fields `camelCase` via model aliases; time is RFC 3339 UTC.

## Logging, config, and secrets

- Standard `logging` (or structlog) configured once at the entry point, JSON in production; never `print` for diagnostics — `print` has no level, no timestamp, no structure, and cannot be filtered or routed.
- Config from environment variables into a typed settings object (e.g. `pydantic-settings`) validated at startup — a missing or malformed variable should kill the boot, not the hundredth request.
- Secrets only from the environment or a secret manager.

## Testing

- [pytest](https://docs.pytest.org/) with plain functions and fixtures — no `unittest.TestCase` classes; pytest's plain asserts give real diffs on failure, and fixtures compose where `setUp` inheritance tangles.
- Fixtures for wiring, parametrize for cases (`@pytest.mark.parametrize`) — each parameter set reports as its own test, so one bad case does not hide the other nine.
- Fakes implement the same protocols the code consumes; patching (`monkeypatch`) is a last resort at process boundaries — patches couple the test to the *import path* of the thing being replaced, so an innocent refactor breaks tests that should not care.
- Mark integration tests (`@pytest.mark.integration`) so the default run stays fast and deterministic — a suite people can run in seconds before every push is a suite that actually gets run.
