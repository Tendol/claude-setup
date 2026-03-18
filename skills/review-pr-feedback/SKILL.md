# Review PR Feedback

Evaluate review comments on your own PR, apply valid fixes, and respond to reviewers.

## When to Use

- PR has review comments that need triage and response
- User says "review the review", "address PR feedback", "handle review comments"

## Core Principles

- **Verify before implementing** — never blindly accept feedback
- **No performative agreement** — no "Great point!", no "You're absolutely right!", no "Thanks for catching that!"
- **Technical correctness over social comfort** — push back with reasoning when feedback is wrong
- **Actions speak** — just fix it. The code shows you heard the feedback.

## Process

1. **Gather context** — find PR, fetch all review comments, read referenced files
2. **Read all feedback completely** before reacting to any single item
3. **If anything is unclear** — STOP. Ask for clarification on all unclear items before implementing any.
4. **Evaluate each comment** using the assessment matrix below
5. **Categorize** each comment into an action
6. **Present summary table** to user before making changes
7. **Apply fixes** for approved items — one at a time, test each
8. **Draft reply comments** for push-backs and acknowledgements
9. **Post and push** after user approves

## Gathering Comments

```bash
gh pr list --head BRANCH_NAME --json number,title,url
gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments \
  --jq '.[] | {id: .id, author: .user.login, body: .body, path: .path, line: .line}'
```

Read every file referenced by review comments to understand code in context.

## Assessment Matrix

| Dimension | Questions |
|-----------|-----------|
| **Validity** | Is the concern technically correct? Does it apply to THIS code? |
| **Severity** | Bug? Code smell? Nitpick? Theoretical edge case? |
| **Scope** | In-scope for this PR, or a follow-up? |
| **Conventions** | Does the suggestion match existing codebase patterns? Grep to check. |
| **Effort vs value** | Trivial fix or significant rework? |
| **YAGNI** | Is the suggested feature actually used? Grep before implementing. |

## Verification

Before accepting any non-obvious claim:
- "This library behaves like X" — check the actual docs (use docs-researcher agent)
- "This pattern causes Y" — trace the execution path in the code
- "This convention is Z" — grep the codebase for existing patterns
- "This should be implemented properly" — grep for actual usage first (YAGNI check)

If you can't easily verify a claim, say so: "I can't verify this without [X]. Should I investigate further?"

## Action Categories

| Action | When |
|--------|------|
| **Apply** | Valid, in-scope, worth fixing now. Matches existing conventions. Reviewer has domain expertise. |
| **Push back** | Incorrect, out of scope, over-engineered, YAGNI, or not worth the trade-off. Breaks existing functionality. Reviewer lacks full context. |
| **Acknowledge** | Valid but out of scope — note as follow-up |
| **Skip** | Pure nitpick, no meaningful impact |

## Presentation

Show findings before acting:

```markdown
| # | File | Comment | Verdict | Action | Reasoning |
|---|------|---------|---------|--------|-----------|
| 1 | Service.js:42 | Missing error handling | Valid bug | Apply | Uncaught exception crashes worker |
| 2 | Controller.js:18 | Extract helper | Over-engineering | Push back | Single use, abstraction not justified |
| 3 | Service.js:90 | Shutdown hooks | Valid, out of scope | Acknowledge | Separate concern, follow-up issue |
```

## Responding

When feedback IS correct:
- "Fixed. [Brief description of what changed]"
- "Good catch - [specific issue]. Fixed in [location]."
- Or just fix it silently in the code.

When pushing back:
- Lead with agreement on what's valid, then explain disagreement
- Use technical reasoning, reference working tests/code
- Be concise and professional

When correcting a wrong pushback:
- "Checked [X] and you're right — it does [Y]. Fixed."
- No long apologies. State the correction and move on.

Reply in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.

## Rules

- Never apply changes without showing user the evaluation first
- Verify reviewer claims before accepting — external feedback is suggestions to evaluate, not orders
- Check codebase conventions (grep) before accepting "best practice" suggestions
- Fix everything you accept — don't half-apply feedback
- Post replies and push only after user approval
- If feedback conflicts with prior architectural decisions, discuss with user first
