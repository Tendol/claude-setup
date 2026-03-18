#!/bin/bash
# install.sh — Symlink claude-setup config into ~/.claude/
# Run this once. After that, git pull updates everything automatically.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing claude-setup from: $SCRIPT_DIR"
echo "Target: $CLAUDE_DIR"
echo ""

# Ensure ~/.claude exists
mkdir -p "$CLAUDE_DIR"

# --- Helper: create symlink with backup ---
link_file() {
    local src="$1"
    local dest="$2"

    if [[ -L "$dest" ]]; then
        # Already a symlink — update it
        rm "$dest"
    elif [[ -f "$dest" ]]; then
        # Existing file — back up
        local backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
        echo "  Backing up existing $dest -> $backup"
        mv "$dest" "$backup"
    fi

    ln -s "$src" "$dest"
    echo "  Linked: $dest -> $src"
}

# --- Helper: create symlink for directory ---
link_dir() {
    local src="$1"
    local dest="$2"

    if [[ -L "$dest" ]]; then
        rm "$dest"
    elif [[ -d "$dest" ]]; then
        local backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
        echo "  Backing up existing $dest -> $backup"
        mv "$dest" "$backup"
    fi

    ln -s "$src" "$dest"
    echo "  Linked: $dest -> $src"
}

# --- Root files ---
echo "Linking root files..."
link_file "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
link_file "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link_file "$SCRIPT_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
chmod +x "$CLAUDE_DIR/statusline-command.sh"

# --- Hooks ---
echo "Linking hooks..."
link_dir "$SCRIPT_DIR/hooks" "$CLAUDE_DIR/hooks"
chmod +x "$SCRIPT_DIR/hooks/"*.sh
chmod +x "$SCRIPT_DIR/hooks/lib/"*.sh 2>/dev/null || true

# --- Rules ---
echo "Linking rules..."
link_dir "$SCRIPT_DIR/rules" "$CLAUDE_DIR/rules"

# --- Skills ---
echo "Linking skills..."
# Link individual skill directories to preserve any existing user skills
mkdir -p "$CLAUDE_DIR/skills"
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    link_dir "$skill_dir" "$CLAUDE_DIR/skills/$skill_name"
done

# --- Agents ---
echo "Linking agents..."
link_dir "$SCRIPT_DIR/agents" "$CLAUDE_DIR/agents"

echo ""
echo "Done! Claude Code will now use your centralized config."
echo ""
echo "To update: cd $SCRIPT_DIR && git pull"
echo "To uninstall: run ./uninstall.sh"
