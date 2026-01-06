#!/bin/bash
# new.sh - Start a fresh game (archives current save)
# Usage: ./new.sh

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

# Archive existing save if present
if [ -f "$SAVE" ]; then
    ARCHIVE="$SKILL_DIR/state/claude.sav.$(date '+%Y%m%d-%H%M%S').qzl"
    mv "$SAVE" "$ARCHIVE"
    echo "Archived previous save to: $ARCHIVE"
fi

# Function to get transcript path
get_transcript_path() {
    if [ -f "$CONFIG" ]; then
        VAULT=$(jq -r '.obsidian_vault // empty' "$CONFIG" 2>/dev/null)
        if [ -n "$VAULT" ] && [ -d "$VAULT" ]; then
            echo "$VAULT/Claude Plays Zork Transcript.md"
            return
        fi
    fi
    echo "$SKILL_DIR/state/TRANSCRIPT.md"
}

TRANSCRIPT=$(get_transcript_path)

# Start new game, do initial look, save
OUTPUT=$(echo -e "look\nsave\n$SAVE\nquit\ny" | dfrotz -m -p -q "$GAME" 2>&1)

# Log to transcript
{
    echo ""
    echo "---"
    echo ""
    echo "# New Game Started - $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo '```'
    echo "$OUTPUT"
    echo '```'
} >> "$TRANSCRIPT"

echo "=== New Game Started ==="
echo ""
echo "$OUTPUT"
