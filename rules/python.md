---
paths:
  - "**/*.py"
---

# Python Conventions

- Use type hints on all function signatures.
- Format with `ruff format`. Lint with `ruff check`.
- Type check with `mypy` in strict mode where possible.
- Use `pathlib.Path` over `os.path`.
- Use `dataclasses` or Pydantic models for structured data — avoid raw dicts.
- Prefer `async/await` for I/O-bound operations.
- Use `logging` module, not `print()`, for operational output.
- Virtual environments: use `.venv/` directory (gitignored).
