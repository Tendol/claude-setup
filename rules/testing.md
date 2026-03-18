---
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/test_*.py"
  - "**/*_test.py"
  - "**/conftest.py"
---

# Test Conventions

- Mock as little as possible. Use real instances, prefer dependency injection.
- Test behavior, not implementation details.
- Test file location: colocate with source file or in a `tests/` directory.

## Python-specific
- Use pytest fixtures over setup/teardown.
- Use `conftest.py` for shared fixtures.
- Use `pytest.mark.parametrize` for data-driven tests.
- Prefer `assert` statements over unittest-style assertions.

## TypeScript-specific
- Use `describe`/`it`/`test` blocks.
- Use `vi.mock()` or `jest.mock()` sparingly — prefer DI.
- Use React Testing Library for component tests — test user interactions, not implementation.
