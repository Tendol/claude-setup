---
name: review-assigned
description: >
  Auto-review PRs assigned to Tendol for review across the wanderu GitHub org.
  Skips already-reviewed, old (>14 days with no activity), and self-authored PRs.
  Posts breaking changes as PR comments and sends suggestions to Slack. Use when
  the user says "review my assigned PRs", "what needs my review", or during
  daily standup.
---

# Review Assigned PRs

Check PRs where Tendol is requested as a reviewer across the wanderu org, auto-review
them, and report findings.

## Process

### Step 1: Fetch review requests

```bash
gh search prs --review-requested=Tendol --owner=wanderu --state=open --json repository,title,number,url,createdAt,updatedAt,author,isDraft,labels,reviewDecision
```

### Step 2: Filter

Skip PRs that match any of these:
- **Already reviewed**: Tendol has already submitted a review (approved or changes requested)
- **Self-authored**: Author is Tendol
- **Stale**: No activity in >14 days and no explicit ping
- **Draft**: Marked as draft (unless explicitly asked)

Report skipped PRs briefly: "Skipping 2 PRs (1 already reviewed, 1 draft)"

### Step 3: For each actionable PR, do a quick review

For each PR that passes the filter:

1. **Fetch the diff**: `gh pr diff <number> -R wanderu/<repo>`
2. **Scan for breaking changes**:
   - API contract changes (endpoint signatures, request/response schemas)
   - Database migration changes (column drops, type changes, table renames)
   - Config/env var changes
   - Dependency major version bumps
   - Removed or renamed exports/public interfaces
3. **Scan for common issues**:
   - Missing error handling on external calls
   - Hardcoded values that should be config
   - Missing tests for new logic
   - Security concerns (SQL injection, unvalidated input, secrets in code)

### Step 4: Report findings

For each reviewed PR, present:

```
### wanderu/nexus#789 — Migrate user sessions to Redis
**Author**: @teammate (opened 2d ago)
**Breaking changes**: Yes — removes `session.store` config key, adds `redis.url` requirement
**Issues found**:
- Missing fallback if Redis connection fails (src/session/store.ts:45)
- No migration guide for the config change

**Recommendation**: Request changes — needs Redis connection error handling
```

### Step 5: Post breaking changes as PR comments

If breaking changes are found, post a comment on the PR flagging them. Format:

```markdown
## Breaking Changes Detected

- Removes `session.store` config key — existing deployments will fail without updating config
- Adds required `redis.url` env var — needs to be set in all environments before deploy

_Auto-detected by daily standup review_
```

**Important**: Do NOT post the comment without showing the user first. Present the
comment content and ask for confirmation before posting.

### Step 6: Send summary to Slack (during standup only)

Post a compact summary:

```
PRs needing my review (3):
⚠️ nexus#789 — Migrate user sessions to Redis (breaking changes!)
👀 wapi#321 — Add rate limiting to search endpoint (looks good)
👀 pservs#100 — Update Greyhound carrier mapping (looks good)
Skipped: 2 (1 already reviewed, 1 draft)
```

### Notes
- Never auto-approve or auto-merge. This skill is for surfacing information, not taking action.
- If a PR is too large to meaningfully review in standup (>500 lines changed), note it
  and suggest a dedicated review session.
- Always show findings to the user before posting any comments on PRs.
