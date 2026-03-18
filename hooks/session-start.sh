#!/bin/bash
# SessionStart hook
# Gathers context and outputs instructions for Claude at session start

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

# Source shared session notes functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/session-notes.sh"

# --- Helper functions ---

has_wayfinder() {
    if [[ -f "$PROJECT_DIR/.claude/mcp.json" ]]; then
        grep -q "wayfinder" "$PROJECT_DIR/.claude/mcp.json" 2>/dev/null && return 0
    fi
    return 1
}

get_branch_status() {
    local current_branch main_branch behind_count

    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [[ -z "$current_branch" ]]; then
        return
    fi

    if git show-ref --verify --quiet refs/heads/main; then
        main_branch="main"
    elif git show-ref --verify --quiet refs/heads/master; then
        main_branch="master"
    else
        return
    fi

    if [[ "$current_branch" == "$main_branch" ]]; then
        return
    fi

    git fetch origin "$main_branch" --quiet 2>/dev/null || true

    behind_count=$(git rev-list --count "HEAD..origin/$main_branch" 2>/dev/null || echo "0")

    if [[ "$behind_count" -gt 0 ]]; then
        echo "Branch is $behind_count commits behind $main_branch. Consider rebasing before making changes."
    fi
}

get_open_pr_status() {
    local current_branch pr_info pr_number pr_state checks_status

    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [[ -z "$current_branch" || "$current_branch" == "main" || "$current_branch" == "master" ]]; then
        return
    fi

    if ! command -v gh &>/dev/null; then
        return
    fi

    pr_info=$(gh pr view --json number,state,statusCheckRollup 2>/dev/null || echo "")
    if [[ -z "$pr_info" ]]; then
        return
    fi

    pr_number=$(echo "$pr_info" | jq -r '.number // empty' 2>/dev/null)
    pr_state=$(echo "$pr_info" | jq -r '.state // empty' 2>/dev/null)

    if [[ -n "$pr_number" && "$pr_state" == "OPEN" ]]; then
        checks_status=$(echo "$pr_info" | jq -r '
            .statusCheckRollup // [] |
            if length == 0 then "no checks"
            elif all(.conclusion == "SUCCESS") then "passing"
            elif any(.conclusion == "FAILURE") then "failing"
            elif any(.state == "PENDING" or .state == "IN_PROGRESS") then "pending"
            else "unknown"
            end
        ' 2>/dev/null)

        echo "Open PR #$pr_number for this branch. CI status: $checks_status"
        if [[ "$checks_status" == "failing" ]]; then
            echo "   Check CI failures before making more changes: gh pr checks"
        fi
    fi
}

# --- Read hook input ---
input=$(cat)

# --- Main output ---

echo "## Session Initialization"
echo ""

# Main branch warning
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
    cat << 'EOF'
### YOU ARE ON MAIN — DO NOT MAKE CHANGES HERE

You MUST create a worktree before doing any work. Invoke `superpowers:using-git-worktrees` NOW, before exploring, planning, or editing anything.

Reading files to understand context is fine. But the moment you need to change anything, you need a worktree.

EOF
fi

# Check for orphaned processes
orphan_warnings=""

dev_server_patterns=("uvicorn" "gunicorn" "fastapi" "flask" "celery.*worker" "next.*dev" "vite")
for pattern in "${dev_server_patterns[@]}"; do
    pids=$(pgrep -f "$pattern" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
        orphan_warnings+="- process ($pattern, PIDs: $pids) — kill $pids\n"
    fi
done

if [[ -n "$orphan_warnings" ]]; then
    echo "### Orphaned Processes Detected"
    echo ""
    echo -e "$orphan_warnings"
fi

# Wayfinder context
if has_wayfinder; then
    cat << 'EOF'
### REQUIRED: Fetch Project Context
Immediately fetch the project documentation from wayfinder:
```
mcp__wayfinder__list_domains
```
Then fetch the relevant service/domain overview based on the project.

EOF
fi

cat << 'EOF'
### Check for Pending Tasks
Run `TaskList` to check if there are pending tasks from previous sessions.

### TDD-First Workflow
- Write failing tests FIRST before implementing any feature or bugfix
- Use `superpowers:test-driven-development` for structured TDD cycles
- Use `superpowers:systematic-debugging` when encountering bugs or test failures
- Use `superpowers:brainstorming` before any creative/feature work
- Use `superpowers:verification-before-completion` before claiming work is done
- Use `finishing-work` before any commit (mandatory)

EOF

# Dynamic context based on git state
branch_warning=$(get_branch_status)
pr_status=$(get_open_pr_status)

if [[ -n "$branch_warning" || -n "$pr_status" ]]; then
    echo "### Current State"
    echo ""
    if [[ -n "$branch_warning" ]]; then
        echo "$branch_warning"
        echo ""
    fi
    if [[ -n "$pr_status" ]]; then
        echo "$pr_status"
        echo ""
    fi
fi

# Recent session notes
recent_notes=$(get_recent_session_notes)
if [[ -n "$recent_notes" ]]; then
    echo "### Recent Session Notes"
    echo "Context from recent sessions:"
    echo ""
    echo '```'
    echo "$recent_notes"
    echo '```'
fi

source=$(echo "$input" | jq -r '.source // empty' 2>/dev/null)

if [[ "$source" == "compact" ]]; then
    project_session_notes_dir="$HOME/.claude/session-notes/$(get_project_name)"
    echo "Session resumed after compaction. Before anything else:"
    echo "Write session notes to: $project_session_notes_dir/$(date +%Y-%m-%d)-<topic>.md"
    echo "Use the compaction summary above as your source. Do this NOW."
fi
