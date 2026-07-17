# Python guidelines

Org addendum for Python. Baseline: [PEP 8](https://peps.python.org/pep-0008/) and the [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html). Cross-language rules: [coding-guidelines.md](../coding-guidelines.md).

## Tooling

- [ruff](https://docs.astral.sh/ruff/) for both formatting and linting.
- [uv](https://docs.astral.sh/uv/) preferred for dependency and environment management; commit the lock file.
- Strict type checking (`pyright` or `mypy --strict`) in CI.

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

- Always the `src/` layout — it prevents accidental imports of the uninstalled package.
- Packages by domain feature; no `utils.py` or `helpers.py` dumping grounds.

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

- Raise specific exceptions; define a small domain exception hierarchy per package.
- Catch narrow: never bare `except:`; catch `Exception` only at process boundaries (request handler, worker loop) where it is logged and translated.
- Use context managers (`with`) for anything that must be released.

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

- **Type hints are required on all public functions and methods.** Data shapes are `dataclass`es (internal) or pydantic models (validated boundaries) — not loose dicts.
- **Protocols over abstract base classes** for interfaces; the consumer defines the protocol it needs.
- **Dependency injection by parameter** — pass collaborators into constructors/functions. No module-level singletons doing I/O at import time.
- Prefer plain functions and modules; introduce a class when there is state plus behavior, not before.

```python
class InvoiceStore(Protocol):
    def find(self, invoice_id: str) -> Row | None: ...

def make_service(store: InvoiceStore) -> InvoiceService: ...
```

Anti-patterns: mutable default arguments, `from x import *`, god modules, import-time side effects, `hasattr`/`isinstance` chains where a protocol or union type fits.

## Concurrency

- `asyncio` for I/O-bound concurrency only; CPU-bound work goes to a process pool or a worker service.
- Do not mix sync and async carelessly: no blocking calls inside `async def` (use `asyncio.to_thread` when unavoidable).
- One event loop, owned at the entry point; libraries never call `asyncio.run`.

## APIs and services

API contract rules (URLs, status codes, errors, pagination): [api-design.md](api-design.md).

- [FastAPI](https://fastapi.tiangolo.com/) is the default service framework; pydantic models validate all request/response bodies.
- Routers stay thin: validate → call service → return model. No business logic in route functions.
- JSON fields `camelCase` via model aliases; time is RFC 3339 UTC.

## Logging, config, and secrets

- Standard `logging` (or structlog) configured once at the entry point, JSON in production; never `print` for diagnostics.
- Config from environment variables into a typed settings object (e.g. `pydantic-settings`) validated at startup.
- Secrets only from the environment or a secret manager.

## Testing

- [pytest](https://docs.pytest.org/) with plain functions and fixtures — no `unittest.TestCase` classes.
- Fixtures for wiring, parametrize for cases (`@pytest.mark.parametrize`).
- Fakes implement the same protocols the code consumes; patching (`monkeypatch`) is a last resort at process boundaries.
- Mark integration tests (`@pytest.mark.integration`) so the default run stays fast and deterministic.
