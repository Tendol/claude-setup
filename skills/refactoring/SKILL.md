# Refactoring

Refactor with verified checkpoints — never break working code.

## Process

1. **VERIFY BASELINE FIRST** — run full verification suite before any changes
2. **Check coverage** — ensure tests exist for code being refactored
3. **Add tests if missing** — no refactoring without test coverage
4. **Make incremental changes**: change -> test -> commit
5. **If tests fail**: revert immediately, understand why, try smaller change

## Rules

- NEVER refactor without passing tests BEFORE starting
- NEVER make multiple refactoring changes without testing between them
- Commit after each successful change (small, atomic commits)
- If something breaks, `git stash` or `git checkout -- .` immediately
- Preserve all public interfaces unless explicitly asked to change them
