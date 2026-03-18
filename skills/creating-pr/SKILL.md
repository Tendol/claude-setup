# Creating a PR

## Title Convention

PR titles use a type prefix in parentheses:

- `(feature) Add trip search autocomplete`
- `(fix) Resolve booking confirmation timeout`
- `(chore) Update dbt model dependencies`
- `(refactor) Simplify route pricing logic`
- `(docs) Add API endpoint documentation`

If a ticket exists in the branch name (e.g., `feat/MAIN-1234-add-auth`), include it:
- `(feature) [MAIN-1234] Add trip search autocomplete`

## Process

1. **Run code review FIRST** — invoke `reviewing-code` skill before creating the PR
2. **Determine type** from the nature of changes:
   - New capability -> `(feature)`
   - Bug fix -> `(fix)`
   - Maintenance/deps/config -> `(chore)`
   - Restructure without behavior change -> `(refactor)`
   - Documentation only -> `(docs)`
3. **Extract ticket from branch name** if present
4. **Create the PR**:
   ```bash
   gh pr create --title "(type) [TICKET] Description" --body "$(cat <<'EOF'
   ## Summary
   <2-3 bullets of what changed and why>

   ## Test Plan
   - [ ] <verification steps>

   ## Migration Notes
   <if applicable — schema changes, env vars, config>
   EOF
   )"
   ```
5. **Monitor CI** — poll `gh pr checks` every 30 seconds, 15-minute timeout
6. **Report status** — share PR URL and CI outcome

## Rules

- NEVER create a PR without running `reviewing-code` first
- NEVER guess deploy/preview URLs — wait for CI to provide them
- Always use the `(type)` prefix convention in PR titles
- Include migration instructions in PR body if there are schema changes
- Tag relevant reviewers if known
- If CI fails, diagnose before asking user what to do
- PR description comes from the branch diff, not memory — be honest about what changed
