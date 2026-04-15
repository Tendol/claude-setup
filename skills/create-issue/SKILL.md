---
name: create-issue
description: Use when the user wants to create a GitHub issue in a wanderu repo with proper metadata (issue type, labels, project). Opens their editor with a type-specific template, applies acquisition_team by default, and links the issue to the Wanderu org project. Triggers on "/create-issue", "create an issue", "open an issue", "file a bug", "follow-up ticket".
---

# create-issue

Interactive skill for creating a GitHub issue in a wanderu repo with guided prompts. Handles the four pieces of metadata `gh issue create` doesn't streamline: the native GitHub issue type, the team label, the org project link, and a type-appropriate body template.

## When to Use

- User invokes `/create-issue` or says "create an issue" / "open an issue" / "file a bug" / "make a follow-up ticket"
- Creating a follow-up issue from PR review feedback
- Creating a bug report, task, feature, or epic in any wanderu repo

## Prerequisites

The `gh` CLI must have the `project` OAuth scope (one-time setup). Without it, Step 7 (add to org project #11) will fail with `authentication token is missing required scopes [project]`.

Check:
```bash
gh auth status 2>&1 | grep -i "token scopes"
```

If `project` is missing, instruct the user:
```bash
gh auth refresh -s project
```

This opens a browser for re-authentication. After that, all subsequent runs work without the prompt.

## Workflow

Follow these steps in order. Do NOT skip prompts — each piece of metadata (type, labels, project, template) matters.

### Step 1 — Detect target repo

Read `git remote get-url origin` in the current working directory. Parse `owner/repo` from patterns like:
- `git@github.com:wanderu/messaging.git` → `wanderu/messaging`
- `https://github.com/wanderu/messaging.git` → `wanderu/messaging`

If not in a git repo, ask the user for `owner/repo`.

### Step 2 — Ask for issue type

Use `AskUserQuestion` with four options:

- **Task** — "A specific piece of work"
- **Bug** — "An unexpected problem or behavior"
- **Feature** — "A request, idea, or new functionality"
- **Epic** — "A larger initiative tracking multiple child issues"

Record the chosen type. Map to the org-level issue type ID:

| Type | GitHub Issue Type ID |
|------|----------------------|
| Task | `IT_kwDOAOgohs4AHiB8` |
| Bug | `IT_kwDOAOgohs4AHiB_` |
| Feature | `IT_kwDOAOgohs4AHiCC` |
| Epic | `IT_kwDOAOgohs4B8lHD` |

### Step 3 — Ask about labels

Two prompts:

1. **`acquisition_team` label** — use `AskUserQuestion` with options `Yes` (default) and `No`. `Yes` is the normal case; `No` only if the issue is for a different team.
2. **Additional labels** — free-text in chat: "Any additional labels? (comma-separated, or press Enter to skip)". Parse comma-separated list.

Build the final label list: `acquisition_team` (if Yes) + any additional labels (trimmed).

### Step 4 — Write template and open editor

Create a temp file (e.g., `/tmp/create-issue-<timestamp>.md`) with the title placeholder on line 1, a blank line, then the type-specific body template from the **Templates** section below.

```
<Replace with issue title>

<type-specific template here>
```

Then open the editor. Default order:
1. `$EDITOR` if set
2. Otherwise `vi`

Run the editor via `Bash` with `run_in_background: false` and a long timeout. The command blocks until the user saves and exits the editor. If the editor can't open interactively (e.g., non-TTY environment), fall back to telling the user:

> "I've written the template to `<path>`. Edit it in your IDE or run `! vi <path>` here, then tell me 'ready'."

When resumed, read the file:
- Line 1 = title (strip leading/trailing whitespace)
- Rest = body (after blank line)
- If the title is still the placeholder, empty, or starts with `<`: abort, do not create the issue. Tell the user the title was not set.

### Step 5 — Create the issue

Run:
```bash
gh issue create \
  --repo <owner>/<repo> \
  --title "<title>" \
  --body-file <tempfile-body> \
  --label "<label1,label2,...>"
```

Write the body to a separate temp file and use `--body-file` to avoid shell-escaping issues with multi-line markdown.

Capture the issue URL from stdout. If `gh` returns an error about a missing label, strip that label from the list and retry once.

### Step 6 — Set GitHub issue type

The `gh` CLI doesn't expose this. Use GraphQL:

```bash
# Get the issue's GraphQL node ID
node_id=$(gh api repos/<owner>/<repo>/issues/<number> --jq .node_id)

# Set the issue type
gh api graphql -f query='
  mutation($issueId: ID!, $typeId: ID!) {
    updateIssueIssueType(input: { issueId: $issueId, issueTypeId: $typeId }) {
      issue { id }
    }
  }
' -f issueId="$node_id" -f typeId="<type_id_from_step_2>"
```

If this call fails, do NOT fail the whole flow — the issue is already created. Warn the user that the type wasn't set and provide the URL so they can set it manually.

### Step 7 — Add to Wanderu org project #11

```bash
gh project item-add 11 --owner wanderu --url <issue_url>
```

If this fails (e.g., missing `project` scope), warn but don't abort:

> "Issue created but could not add to project 11. Run `gh auth refresh -s project` to grant project scope, then add manually."

### Step 8 — Print result

Print the final issue URL. If `pbcopy` is available on the platform, pipe the URL to it so the user can paste it directly.

Example output:

> Created: https://github.com/wanderu/messaging/issues/54
> - Type: Task
> - Labels: acquisition_team
> - Project: Wanderu (#11)
> - URL copied to clipboard

## Templates

Use the template matching the chosen issue type.

### Task

```markdown
## Context
<!-- Why are we doing this? What's the relevant background? -->

## Action item
<!-- What specifically needs to be done? -->

## References
<!-- Related PRs, issues, Slack threads, etc. -->
```

### Bug

```markdown
## Steps to reproduce
1.
2.

## Expected behavior

## Actual behavior

## Impact
<!-- Who is affected, how severe? -->

## References
<!-- Logs, screenshots, related issues -->
```

### Feature

```markdown
## Problem
<!-- What user or business need does this address? -->

## Proposed solution

## Success criteria
<!-- How do we know this worked? -->

## References
```

### Epic

```markdown
<!-- One-paragraph description of the initiative -->

## Goal
<!-- What's the broader objective and why now? -->

## Scope
<!-- What's in. What's explicitly out. -->

## Open Work

### In Progress
- [ ] #<issue> — <title>

### In Review
- [ ] #<issue> — <title>

### Ready
- [ ] #<issue> — <title>

### Backlog
- [ ] #<issue> — <title>

## Completed
<!-- Move items here as they land. Group by phase/theme. -->
- [x] #<issue> — <title>

## Success criteria
<!-- How do we know the epic is done? -->
```

## Error Handling

| Condition | Response |
|-----------|----------|
| `gh` not authed | Tell user to run `gh auth login`. Abort. |
| Not in a git repo | Ask user for `owner/repo`. |
| Editor saved with empty or placeholder title | Abort. Do not create issue. |
| Label doesn't exist in repo | Strip label, retry `gh issue create` once. Warn. |
| Issue type mutation fails | Warn. Issue is still created; user can set type manually. |
| Project add fails (missing scope) | Warn. Suggest `gh auth refresh -s project`. |

## Red Flags — STOP

- Creating the issue without asking for type → always ask
- Skipping the editor step and inlining title/body → the user picked `$EDITOR` deliberately for template prefill
- Defaulting `acquisition_team` to No → it's the common case, default Yes
- Proceeding when the title is still the placeholder → abort instead

## Reference IDs (wanderu org)

These are stable values you can use directly:

- Org login: `wanderu`
- Org project: `#11` "Wanderu"
- Issue type IDs: see Step 2 table above
- Fetch with: `gh api orgs/wanderu/issue-types`
