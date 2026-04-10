---
name: daily-standup
description: >
  Morning kickoff routine: recap yesterday's session notes, check open PRs,
  review assigned PRs, show todos, and offer deep dives. Use when starting
  the day or when the user says "standup", "morning kickoff", "daily standup",
  or "what's on my plate today".
---

# Daily Standup

Morning kickoff that runs two workflows in sequence.

## Process

### Part 1 — Yesterday Recap

Scan all project subdirectories under `~/.claude/session-notes/` for yesterday's date (`YYYY-MM-DD.md`). Each wanderu repo writes its own session notes to `~/.claude/session-notes/<project>/YYYY-MM-DD.md` via the `finishing-work` skill. Aggregate all notes found across projects into a 3-5 bullet summary of what was accomplished — repos touched, PRs opened/merged, key decisions, anything left in progress. If no notes exist for yesterday (e.g., Monday morning after a weekend), check the most recent session notes across all projects and note the date. Keep it brief — this is context-setting, not a full recap.

After the recap, invoke the `todo` skill (list operation) for any items due today or overdue. If there are any, call them out here — e.g., "Due today: finish PLAT-211 report view". This gives an immediate sense of what's on the plate before diving into PRs.

### Part 2 — My PRs

Invoke the `my-prs` skill.

This checks all open PRs across wanderu, shows their status, and posts to Slack.

### Part 3 — Review Assigned PRs

Invoke the `review-assigned` skill.

This auto-reviews assigned PRs (skipping already-reviewed, old, and self-authored), posts breaking changes as PR comments, and sends suggestions to Slack.

### Part 4 — GitHub Project Board Items

Query all wanderu org GitHub Projects for issues assigned to Tendol in **Ready** or **In Progress** status, filtered to labels: `tech-debt`, `bug`, `improvement`, `enhancement`, `help-wanted`.

Steps:
1. `gh project list --owner wanderu --format json` to discover all projects
2. For each project: `gh project item-list <number> --owner wanderu --format json`
3. Parse items with node/jq — filter by assignee = Tendol, status in (Ready, In Progress), and matching labels
4. Display grouped by status (Ready first, then In Progress), showing issue number, title, labels, and linked PR if any

Requires `read:project` scope on the gh token.

### Part 5 — Todo list

Invoke the `todo` skill (list operation).

Show active todo items. Highlight any items due today or overdue.

### Part 6 — Offer deep dives

After all parts complete, ask if you want to look at anything specific — a PR to merge, a breaking change to investigate, a project board item to pick up, a todo to knock out, etc.
