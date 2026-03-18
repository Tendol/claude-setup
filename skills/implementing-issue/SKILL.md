# Implementing a GitHub Issue

Orchestrate end-to-end implementation of a GitHub issue.

## Process

1. **Fetch issue** — `gh issue view <number>`
2. **Display summary** — show title, description, labels. Get user confirmation.
3. **Create branch**:
   - Determine prefix from labels: Bug -> `fix/`, Feature -> `feat/`, Improvement -> `chore/`
   - Format: `{prefix}/{issue-number}-{slug}`
4. **Create worktree** — invoke `superpowers:using-git-worktrees`
5. **Implement with TDD** — invoke `superpowers:test-driven-development`
6. **Finish work** — invoke `finishing-work` skill
7. **Create PR** — invoke `creating-pr` skill, reference issue in PR body with `Closes #<number>`

## Rules

- EVERY step above marked with "invoke" is REQUIRED — do not skip
- Always confirm with user before starting implementation
- If implementation reveals the issue needs clarification, pause and ask
