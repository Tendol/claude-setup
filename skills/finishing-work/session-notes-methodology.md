# Session Notes Methodology

Pattern for maintaining persistent memory across sessions.

## Where to Write

- `~/.claude/session-notes/<project-name>/YYYY-MM-DD-<topic>.md`

## What to Track

- Architectural decisions and their rationale
- Corrections to AI approach (original mistake -> correct approach)
- Working patterns (testing strategies, debugging approaches)
- Bugs found and root causes
- Performance observations
- Team conventions discovered

## What NOT to Track

- Routine bug fixes (the fix is in the code)
- Obvious implementation details
- Standard framework usage
- Temporary workarounds (unless they reveal a deeper issue)

## Entry Format

```markdown
## YYYY-MM-DD: Title

### Context
What was being worked on and why.

### Decisions Made
- Decision 1: Rationale
- Decision 2: Rationale

### Corrections
- **Wrong**: What was tried/assumed
- **Right**: What actually works and why

### Learnings
Key takeaways for future sessions.

### Open Questions
Unresolved items for next session.
```

## When to Extract to Formal Docs

When a pattern appears 3+ times in session notes, extract it to:
- A rule in `rules/` if it's a convention
- A skill in `skills/` if it's a workflow
- CLAUDE.md if it's a global preference
