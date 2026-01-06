#!/bin/bash
# setup.sh - Configure Obsidian vault for learnings sync
# Usage: ./setup.sh [vault_path]

set -e

# Get script directory and skill root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$SKILL_DIR/state/config.json"

VAULT_PATH="$1"

if [ -z "$VAULT_PATH" ]; then
    echo "=== Zork Skill Setup ==="
    echo ""
    echo "This skill can sync your play transcript and learnings to an Obsidian vault."
    echo ""
    if [ -f "$CONFIG" ]; then
        CURRENT=$(jq -r '.obsidian_vault // "not set"' "$CONFIG" 2>/dev/null)
        echo "Current setting: $CURRENT"
    else
        echo "Current setting: not configured (using local state/)"
    fi
    echo ""
    echo "To configure, run:"
    echo "  setup.sh /path/to/your/obsidian/vault"
    echo ""
    echo "To clear the setting and use local storage:"
    echo "  setup.sh clear"
    exit 0
fi

if [ "$VAULT_PATH" = "clear" ]; then
    if [ -f "$CONFIG" ]; then
        rm "$CONFIG"
        echo "Cleared Obsidian vault setting. Using local state/ directory."
    else
        echo "No config to clear."
    fi
    exit 0
fi

# Validate path
if [ ! -d "$VAULT_PATH" ]; then
    echo "Error: Directory does not exist: $VAULT_PATH"
    exit 1
fi

# Save config
echo "{\"obsidian_vault\": \"$VAULT_PATH\"}" > "$CONFIG"

echo "=== Configuration Saved ==="
echo ""
echo "Obsidian vault: $VAULT_PATH"
echo ""
echo "Transcript and learnings will sync to:"
echo "  - $VAULT_PATH/Claude Plays Zork Transcript.md"
echo "  - $VAULT_PATH/Claude Plays Zork Learnings.md"
