---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "lib/**/*.ts"
  - "lib/**/*.py"
  - "src/**/*.py"
  - "app/**/*.py"
  - "app/**/*.ts"
  - "app/**/*.tsx"
---

# TDD Enforcement

When editing source files, follow the TDD cycle:

1. **RED**: Write a failing test first (`*.test.*`, `*.spec.*`, or `test_*.py`)
2. **GREEN**: Write minimal code to make the test pass
3. **REFACTOR**: Clean up while keeping tests green

Do NOT edit source files before writing tests. Do NOT skip the test-running step.

- **Python**: Use pytest. Test files: `test_*.py` or `*_test.py`
- **TypeScript**: Use vitest or jest. Test files: `*.test.ts` or `*.spec.ts`
