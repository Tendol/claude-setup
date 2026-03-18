# Reviewing PRs

Review someone else's PR with verified, line-level findings posted as inline comments.

## Process

1. **Gather context** — `gh pr diff`, read changed files, understand the goal
2. **Run parallel review agents**:
   - code-reviewer
   - silent-failure-hunter
   - pr-test-analyzer
3. **Verify each finding** — use `verified-analysis` skill for every finding
4. **Classify findings**:
   - **Validity**: VALID / UNCERTAIN / FALSE POSITIVE
   - **Severity**: blocking / suggestion / nit
5. **Map each finding to a diff location** — file path and line number in the diff
6. **Present to user** — show all findings for per-finding approval before posting
7. **Post review** — single GitHub review with inline comments on specific lines

## Posting Line-Level Comments

Use the GitHub API to submit a single review with all comments attached to specific lines:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  -f event="COMMENT" \
  -f body="Summary of review findings" \
  -f 'comments=[
    {
      "path": "src/service.py",
      "line": 42,
      "body": "This catch block swallows the exception silently. Consider logging or re-raising."
    },
    {
      "path": "src/routes/api.py",
      "line": 15,
      "body": "Input is not validated here — use a Pydantic model to validate before processing."
    }
  ]'
```

### Key fields per comment

| Field | Description |
|-------|-------------|
| `path` | File path relative to repo root |
| `line` | Line number in the **new version** of the file (right side of diff) |
| `side` | `RIGHT` (new code, default) or `LEFT` (deleted code) |
| `start_line` | For multi-line comments, the first line of the range |
| `body` | The comment text (markdown supported) |

### Review event types

| Event | When to use |
|-------|-------------|
| `COMMENT` | General feedback, no explicit approval or rejection |
| `APPROVE` | All looks good (only if user explicitly says to approve) |
| `REQUEST_CHANGES` | Blocking issues found (only if user explicitly says to request changes) |

## Comment Format

Keep comments concise and actionable:

```markdown
**[severity]** Brief title

Description of the issue and why it matters.

Suggested fix:
\`\`\`python
# corrected code here
\`\`\`
```

Severity tags: `[blocking]`, `[suggestion]`, `[nit]`

## Presentation (Before Posting)

Show the user exactly what will be posted:

```markdown
| # | File:Line | Severity | Comment Preview | Post? |
|---|-----------|----------|-----------------|-------|
| 1 | src/service.py:42 | blocking | Silent exception in catch block | Y |
| 2 | src/routes/api.py:15 | suggestion | Missing input validation | Y |
| 3 | src/utils.py:8 | nit | Unused import | Y |
```

User approves/removes individual comments, then post as a single review.

## Rules

- UNCERTAIN findings are NOT posted unless explicitly approved by user
- Never post a review without showing user the full table first
- Always post as a **single review** with all inline comments — never individual comments
- Default to `COMMENT` event — only use `APPROVE` or `REQUEST_CHANGES` if user explicitly asks
- Store artifacts in `~/.claude/reviews/<project>/pr-<number>/`
- Be constructive — suggest fixes, not just problems
- Include code suggestions when the fix is clear
