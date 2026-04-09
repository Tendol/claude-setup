# Session Notes

Write or append session notes for the current work session. Use when finishing work, ending a session, or when the user asks to capture what was done.

## Process

1. **Determine the file path**: `~/.claude/session-notes/<project-name>/YYYY-MM-DD.md`
2. **Check if today's file exists**. If so, read it and append a new `##` section. If not, create it with a `# YYYY-MM-DD` heading.
3. **Gather context**: current branch, PR number (if any), what was worked on
4. **Write using the exact template below** — do not skip or rename sections. Use "None" if a section has nothing to report.

## Template

```markdown
## PR #<number> (`<branch-name>`) — <Title>

### Context
What was being worked on and why.

### Done
- Concrete actions completed this session

### Decisions Made
- Decision: Rationale

### Corrections
- **Wrong**: What was tried/assumed
- **Right**: What actually works and why

### Learnings
Key takeaways for future sessions.

### Open Questions
Unresolved items for next session.
```

If work is not associated with a PR, use `## <branch-name> — <Title>` or `## <Title>` as the heading.

## Rules

- One file per date per project — never create separate files for each session or topic
- Always use the exact template — consistency matters for readability
- Keep entries concise — this is a record, not a journal
- Don't track routine fixes, obvious implementation details, or standard framework usage
- Do track decisions, corrections, learnings, and open questions
