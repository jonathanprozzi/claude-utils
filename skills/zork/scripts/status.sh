#!/bin/bash
# status.sh - Show current game status (look + inventory)
# Usage: ./status.sh

set -e

# Get script directory and skill root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
GAME="$SKILL_DIR/data/zork1.z3"
SAVE="$SKILL_DIR/state/claude.sav.qzl"
CONFIG="$SKILL_DIR/state/config.json"

# Check if game file exists
if [ ! -f "$GAME" ]; then
    echo "Error: Game file not found at $GAME"
    exit 1
fi

# Check if save file exists
if [ ! -f "$SAVE" ]; then
    echo "No saved game found. Start a new game with /zork new or just /zork look"
    exit 0
fi

# Run look and inventory commands
OUTPUT=$(echo -e "look\ninventory\nquit\ny" | dfrotz -m -p -q -L "$SAVE" "$GAME" 2>&1)

echo "=== Current Status ==="
echo ""
echo "$OUTPUT"

# Show Obsidian config if set
if [ -f "$CONFIG" ]; then
    VAULT=$(jq -r '.obsidian_vault // empty' "$CONFIG" 2>/dev/null)
    if [ -n "$VAULT" ]; then
        echo ""
        echo "=== Sync Config ==="
        echo "Obsidian vault: $VAULT"
    fi
fi
