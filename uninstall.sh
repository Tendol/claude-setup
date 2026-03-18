#!/bin/bash
# uninstall.sh — Remove symlinks created by install.sh
# Restores backups if they exist.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Uninstalling claude-setup symlinks from: $CLAUDE_DIR"
echo ""

unlink_item() {
    local dest="$1"
    if [[ -L "$dest" ]]; then
        local target
        target=$(readlink "$dest")
        if [[ "$target" == "$SCRIPT_DIR"* ]]; then
            rm "$dest"
            echo "  Removed: $dest"

            # Restore latest backup if one exists
            local latest_backup
            latest_backup=$(ls -t "${dest}.backup."* 2>/dev/null | head -1 || true)
            if [[ -n "$latest_backup" ]]; then
                mv "$latest_backup" "$dest"
                echo "  Restored: $latest_backup -> $dest"
            fi
        fi
    fi
}

# Root files
unlink_item "$CLAUDE_DIR/settings.json"
unlink_item "$CLAUDE_DIR/CLAUDE.md"
unlink_item "$CLAUDE_DIR/statusline-command.sh"

# Directories
unlink_item "$CLAUDE_DIR/hooks"
unlink_item "$CLAUDE_DIR/rules"
unlink_item "$CLAUDE_DIR/agents"

# Individual skills
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    unlink_item "$CLAUDE_DIR/skills/$skill_name"
done

echo ""
echo "Done. Symlinks removed. Backups restored where available."
