# Reviewing Code

Automated review-fix-verify cycle for your own code before committing or creating a PR.

## Modes

- **Pre-commit**: Reviews branch diff against main
- **Pre-PR**: Full code review + PR readiness checks

## Process

1. **Get git SHAs for the review range**:
   ```bash
   # Detect the base branch (upstream tracking, or fall back to main/master)
   BASE_BRANCH=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null | sed 's|origin/||' \
     || (git show-ref --verify --quiet refs/heads/main 2>/dev/null && echo main) \
     || echo master)
   BASE_SHA=$(git merge-base HEAD "origin/$BASE_BRANCH")
   HEAD_SHA=$(git rev-parse HEAD)
   git diff --stat $BASE_SHA..$HEAD_SHA
   ```
   If the detected base looks wrong, ask the user: "This branch appears to be based on `<BASE_BRANCH>` — is that correct?"

2. **Launch review agents** via `review-orchestrator` agent (parallel):
   - code-reviewer — guidelines compliance and bug detection
   - silent-failure-hunter — error handling audit
   - pr-test-analyzer — test coverage analysis
   Provide each agent with: what was implemented, the plan/requirements, BASE_SHA, HEAD_SHA

3. **For each finding**:
   - Verify with `verified-analysis` skill
   - Classify: VALID / UNCERTAIN / FALSE POSITIVE
   - Fix VALID findings immediately

4. **Run verification** — invoke `verifying` skill after fixes

5. **Repeat** — max 3 review rounds

6. **Write checkpoint** to `~/.claude/reviews/<project>/branch-<name>/checkpoint.md`

## Review Checklist

Beyond what agents catch, verify:
- **Requirements**: All planned functionality implemented? No scope creep?
- **Architecture**: Sound design? Proper separation of concerns? Integrates with existing code?
- **Production readiness**: Migration strategy? Backward compatibility? Breaking changes documented?

## Rules

- Max 3 review rounds — if issues persist after 3, report remaining
- Fix VALID findings, skip FALSE POSITIVE, flag UNCERTAIN for user
- Always provide file:line references — never vague feedback
- Acknowledge what's well-done, not just problems
- Give a clear verdict: Ready to merge / With fixes / Not ready
