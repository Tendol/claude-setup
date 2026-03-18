# Verifying

Run the full verification suite for the current project.

## Process

1. **Detect project type** and determine verification commands:
   - **Python**: `ruff check .`, `ruff format --check .`, `mypy .`, `pytest`
   - **TypeScript/Next.js**: `npx eslint .`, `npx tsc --noEmit`, `npx vitest run` or `npx jest`
   - **dbt**: `dbt compile`, `dbt test`
   - **Task-based**: `task lint`, `task test` (check Taskfile.yaml first)
2. **Run in order**: lint -> fix -> type check -> test -> report
3. **Max 3 attempts** per check type before reporting failure
4. **Show actual command output** as evidence

## Rules

- NEVER claim "done" without fresh verification output
- If lint has auto-fix (`ruff check --fix`, `eslint --fix`), run it
- Report the actual output, not a summary
- If tests fail, include the failing test names and error messages
