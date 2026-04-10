---
name: my-prs
description: >
  Check all open PRs authored by Tendol across the wanderu GitHub org. Shows
  CI status, review status, merge readiness, and age. Use when the user says
  "my PRs", "check my pull requests", "what PRs do I have open", or during
  daily standup.
---

# My PRs

Check all open PRs authored by Tendol across the wanderu org and report their status.

## Process

### Step 1: Fetch open PRs

Use the GitHub CLI to find all open PRs by Tendol across the wanderu org:

```bash
gh search prs --author=Tendol --owner=wanderu --state=open --json repository,title,number,url,createdAt,reviewDecision,statusCheckRollup,isDraft,labels
```

### Step 2: For each PR, determine status

Categorize each PR into one of these states:

| Status | Meaning |
|--------|---------|
| **Ready to merge** | Approved + CI passing + not draft |
| **Approved, CI failing** | Has approval but checks failing |
| **Changes requested** | Reviewer requested changes |
| **Waiting for review** | No review decision yet, CI passing |
| **CI failing** | Checks failing, no review yet |
| **Draft** | Marked as draft |

### Step 3: Display summary

```
## My Open PRs

### Ready to merge
- wanderu/nexus#456 — Add carrier timeout retry (approved, CI green, 2d old)

### Waiting for review
- wanderu/wapi#123 — Fix session error handling (CI green, 1d old)
- wanderu/pservs#89 — Update carrier mapping (CI green, 3d old)

### CI failing
- wanderu/wtix#234 — Refactor booking flow (lint error, 5d old)

### Draft
- wanderu/nexus#500 — WIP: New report view (4d old)

**Summary: 5 open PRs — 1 ready to merge, 2 awaiting review, 1 CI failing, 1 draft**
```

### Step 4: Post to Slack (during standup only)

If running as part of daily-standup, post the summary to the user's Slack. Use a concise format:

```
My open PRs (5):
✅ nexus#456 — Add carrier timeout retry (ready to merge)
⏳ wapi#123 — Fix session error handling (awaiting review)
⏳ pservs#89 — Update carrier mapping (awaiting review)
❌ wtix#234 — Refactor booking flow (CI failing)
📝 nexus#500 — WIP: New report view (draft)
```

### Notes
- Sort within each category by age (oldest first) to surface stale PRs.
- Flag PRs older than 5 days as potentially stale.
- If a PR has merge conflicts, note that in the status.
