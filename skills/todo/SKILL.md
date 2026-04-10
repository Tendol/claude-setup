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

### Notes
- If `~/.claude/todo.json` doesn't exist, create it with an empty array `[]`.
- Always write the file back after mutations.
- When listing during standup (Part 1 or Part 4), keep it compact — skip the recently completed section unless asked.
