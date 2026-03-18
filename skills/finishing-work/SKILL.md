# Finishing Work

Process before committing — ensures quality, captures learnings, and handles branch completion.

## Process

### Phase 1: Quality Gate

1. **Reflect on session** — identify learnings, corrections, patterns worth codifying
2. **Update docs if needed** — session notes, convention docs, skills
3. **Run verification** — invoke `verifying` skill (REQUIRED — do not skip)
4. **Run code review** — invoke `reviewing-code` skill (REQUIRED — do not skip)
5. **Commit** — only after verification AND code review pass

### Phase 2: Branch Completion

After committing, determine the base branch and present options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

#### Option 1: Merge Locally
- Switch to base branch, pull latest, merge feature branch
- Verify tests on merged result
- Delete feature branch, cleanup worktree

#### Option 2: Push and Create PR
- Push branch with `-u`
- Invoke `creating-pr` skill for full PR workflow
- Keep worktree (PR may need more work)

#### Option 3: Keep As-Is
- Report branch name and worktree path
- Don't cleanup anything

#### Option 4: Discard
- Require typed "discard" confirmation first
- Show what will be deleted (branch, commits, worktree)
- Only proceed after explicit confirmation

### Phase 3: Worktree Cleanup

For Options 1 and 4, if in a worktree:
```bash
git worktree remove <worktree-path>
```

For Options 2 and 3: keep worktree.

## What to Capture in Session Notes

- Architectural decisions and their rationale
- Corrections to AI approach (what was wrong, what's correct)
- Working patterns discovered
- Testing strategies that worked
- Bugs found and their root causes

## Rules

- NEVER commit without running both `verifying` and code review
- NEVER proceed to Phase 2 with failing tests
- Include actual command output evidence in commit message
- Write session notes to `~/.claude/session-notes/<project>/`
- If verification fails, fix before committing — don't commit broken code
- NEVER force-push or delete work without explicit confirmation
