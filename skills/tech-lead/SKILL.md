# Tech Lead

Invoke the tech-lead agent for project direction, production readiness, and architecture review. Findings are posted as GitHub issues.

## When to Use

Any time the user mentions "tech-lead" or asks about project direction, readiness, or architecture.

## Mode Selection

Run **only** the mode that matches what the user asked. Do NOT run all three.

| User says | Mode |
|-----------|------|
| "what should I work on" / "check for tech debt" / "what's next" | Mode 1: Direction |
| "is this ready to ship" / "can we deploy this" / "production readiness" | Mode 2: Readiness |
| "review the architecture" / "what's the state of this project" | Mode 3: Architecture |

If unclear, ask: "Which would you like — direction on what to work on, readiness check for this branch, or architecture review?"

### Mode 1: What Should I Work On?

1. Dispatch `tech-lead` agent with prompt:
   > Scan this codebase and recommend what to work on next. Check: open issues, recent bug fixes, test coverage gaps, dependency freshness, high-churn/low-test areas, TODO/FIXME/HACK comments, tech debt. Prioritize by risk and impact.

2. Present prioritized list to user.

3. For each significant finding, create a GitHub issue:
   ```bash
   gh issue create \
     --title "(tech-debt) <concise title>" \
     --body "$(cat <<'EOF'
   ## Problem
   <what's wrong and where>

   ## Risk
   <what happens if we ignore this>

   ## Recommendation
   <what to do about it>

   ## Evidence
   <file:line references, grep results, metrics>

   ---
   *Identified by tech-lead agent*
   EOF
   )" \
     --label "tech-debt"
   ```

4. Show user the list of created issues.

### Mode 2: Is This Branch Ready?

1. Gather branch context:
   ```bash
   BASE_BRANCH=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null | sed 's|origin/||' \
     || (git show-ref --verify --quiet refs/heads/main 2>/dev/null && echo main) \
     || echo master)
   git diff --stat "origin/$BASE_BRANCH"..HEAD
   git log --oneline "origin/$BASE_BRANCH"..HEAD
   ```

2. Dispatch `tech-lead` agent with prompt:
   > Run a full production readiness assessment on this branch. Evaluate: test coverage of critical paths, monitoring/observability, deployment confidence, backward compatibility, rollback plan, blast radius. Give a clear verdict: SHIP IT / SHIP WITH CAVEATS / NOT READY.

3. Present the verdict to user.

4. If there are findings (SHIP WITH CAVEATS or NOT READY), create a single GitHub issue:
   ```bash
   gh issue create \
     --title "(release) Production readiness: <branch-name>" \
     --body "$(cat <<'EOF'
   ## Verdict: [SHIP IT / SHIP WITH CAVEATS / NOT READY]
   **Confidence:** [HIGH / MEDIUM / LOW]

   ## What's Solid
   <strengths>

   ## Must Fix Before Deploy
   - [ ] <blocking items>

   ## Should Fix After Deploy
   - [ ] <follow-up items>

   ## Evidence
   <test output, coverage gaps, missing monitoring>

   ---
   *Assessed by tech-lead agent*
   EOF
   )" \
     --label "release"
   ```

5. If verdict is SHIP IT, skip issue creation unless user asks.

### Mode 3: Architecture Review

1. Dispatch `tech-lead` agent with prompt:
   > Review the architecture of this project. Analyze: project structure, key entry points, data flow, dependencies, coupling, single points of failure, scaling bottlenecks. Produce a text architecture diagram, coupling analysis, and ranked recommendations.

2. Present findings to user.

3. Create GitHub issues for actionable recommendations:
   ```bash
   gh issue create \
     --title "(architecture) <concise recommendation>" \
     --body "$(cat <<'EOF'
   ## Current State
   <what exists now>

   ## Problem
   <why this matters — scaling, coupling, reliability>

   ## Recommendation
   <what to change>

   ## Impact
   <what improves if we do this>

   ## Effort Estimate
   [Small / Medium / Large]

   ---
   *Identified by tech-lead agent*
   EOF
   )" \
     --label "architecture"
   ```

4. Show user the list of created issues.

## Issue Conventions

- **Title prefix**: `(tech-debt)`, `(release)`, or `(architecture)` to match creating-pr convention
- **Labels**: Create the label if it doesn't exist — `gh label create <name> --force`
- **No duplicates**: Before creating, search for existing issues: `gh issue list --search "<title keywords>" --state open`
- **Link to code**: Include file:line references so findings are traceable

## Presentation

Before creating any issues, show the user:

```markdown
| # | Type | Title | Severity | Create Issue? |
|---|------|-------|----------|---------------|
| 1 | tech-debt | Missing index on bookings.user_id | Critical | Y |
| 2 | tech-debt | Dead code in legacy pricing module | Minor | Y |
| 3 | architecture | Search service tightly coupled to DB | Significant | Y |
```

User approves/removes before issues are created.

## Rules

- NEVER create issues without showing user the table first
- NEVER create duplicate issues — always search first
- Back every finding with evidence from the code (file:line, grep output, test results)
- Be direct about severity — don't soften "this will break" into "you might want to consider"
- If the project is in good shape, say so. Don't invent concerns to fill a report.
