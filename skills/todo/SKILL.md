---
name: todo
description: >
  Manage a personal todo list stored in a local JSON file. Supports add, list,
  complete, and remove operations. Use when the user says "add todo", "show todos",
  "what's on my list", "mark done", or any task management request.
---

# Todo

Manage a personal todo list stored at `~/.claude/todo.json`.

## File format

```json
[
  {
    "id": 1,
    "text": "Finish PLAT-211 report view",
    "due": "2026-04-07",
    "added": "2026-04-04",
    "completed": null,
    "tags": ["nexus", "plat"]
  }
]
```

## Operations

Determine which operation the user wants:

| Operation | Trigger | Action |
|-----------|---------|--------|
| **list** | "show todos", "what's on my list", standup context | Read the file, display active (non-completed) items. Highlight overdue and due-today items. |
| **add** | "add todo", "remind me to" | Append a new item. Auto-increment ID. Parse due date if given (e.g., "by Friday" -> next Friday's date). |
| **complete** | "done with", "mark X done", "finished X" | Set `completed` to today's date. Match by ID or fuzzy text match. |
| **remove** | "remove todo", "delete todo" | Remove the item entirely. Confirm before removing. |

### List output format

```
## Todos

🔴 **Overdue**
- [ ] #3 — Finish PLAT-211 report view (due Apr 5)

📅 **Due today**
- [ ] #5 — Review wapi migration PR (due Apr 6)

📋 **Upcoming**
- [ ] #7 — Write carrier timeout retry logic (due Apr 10)
- [ ] #8 — Update pservs docs (no due date)

✅ **Recently completed** (last 3 days)
- [x] #2 — Fix session error handling (completed Apr 5)
```

### GitHub Project Board Items

When listing todos (any context), also query all wanderu org GitHub Projects for issues assigned to Tendol in **Ready** or **In Progress** status, filtered to labels: `tech-debt`, `bug`, `improvement`, `enhancement`, `help-wanted`.

Steps:
1. `gh project list --owner wanderu --format json` to discover all projects
2. For each project: `gh project item-list <number> --owner wanderu --format json`
3. Filter by assignee = Tendol, status in (Ready, In Progress), and matching labels
4. Show after the local todo list under a `## GitHub Project Items` heading

Requires `read:project` scope on the gh token.

### Notes
- If `~/.claude/todo.json` doesn't exist, create it with an empty array `[]`.
- Always write the file back after mutations.
- When listing during standup (Part 1 or Part 5), keep it compact — skip the recently completed section unless asked.
