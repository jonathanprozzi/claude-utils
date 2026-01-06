#!/bin/bash
# play.sh - Execute one Zork command and return output
# Usage: ./play.sh "go north"

set -e

# Get script directory and skill root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
GAME="$SKILL_DIR/data/zork1.z3"
SAVE="$SKILL_DIR/state/claude.sav.qzl"
CONFIG="$SKILL_DIR/state/config.json"

CMD="$1"

if [ -z "$CMD" ]; then
    echo "Usage: play.sh <command>"
    echo "Example: play.sh 'go north'"
    exit 1
fi

# Check if game file exists
if [ ! -f "$GAME" ]; then
    echo "Error: Game file not found at $GAME"
    exit 1
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

# Run the command
if [ -f "$SAVE" ]; then
    # Load from save, execute command, save (with overwrite), quit
    OUTPUT=$(echo -e "$CMD\nsave\n$SAVE\ny\nquit\ny" | dfrotz -m -p -q -L "$SAVE" "$GAME" 2>&1)
else
    # New game, execute command, save, quit
    OUTPUT=$(echo -e "$CMD\nsave\n$SAVE\nquit\ny" | dfrotz -m -p -q "$GAME" 2>&1)
fi

# Log to transcript
{
    echo ""
    echo "## $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "> $CMD"
    echo ""
    echo '```'
    echo "$OUTPUT"
    echo '```'
} >> "$TRANSCRIPT"

# Output the result
echo "$OUTPUT"
