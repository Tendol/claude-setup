# Debugging CI Failures

Diagnose CI failures through structured root-cause analysis.

## Process

1. **Identify failing step** — `gh run view <run-id>`
2. **Pull logs** — use a subagent to extract relevant log sections (never dump raw logs)
3. **Check recent changes** — `git diff main -- .github/workflows/ Dockerfile docker-compose* alembic/ migrations/`
4. **Classify failure**:
   - **Test/Lint**: Test failures, linting errors, type check failures
   - **Build**: Dependency resolution, compilation, Docker build errors
   - **Migration**: Database migration failures
   - **Infrastructure**: OOM, scheduling, health checks, secrets missing
   - **Transient**: Timeout, rate limit, connection reset
   - **Unknown**: Cannot determine root cause

## Actions by Classification

- **Test/Lint**: Read test output, reproduce locally, fix
- **Build**: Check dependency changes, lockfile conflicts
- **Migration**: Check migration ordering, verify DB state
- **Infrastructure**: Check Dockerfile, resource limits, env vars
- **Transient**: Re-run ONLY with positive evidence (timeout, rate limit, connection reset in logs)
- **Unknown**: Report findings, do NOT suggest re-run

## Rules

- NEVER suggest re-run for Unknown classification
- NEVER dump raw CI logs into context — use subagent to extract relevant sections
- Check if the failure reproduces locally before suggesting fixes
