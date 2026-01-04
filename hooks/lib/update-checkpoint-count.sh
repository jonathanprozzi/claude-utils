#!/bin/bash
# Update checkpoint count in daily note's Claude Sessions section
# Usage: update-checkpoint-count.sh <vault_path> <date_yyyy_mm_dd> <checkpoint_summary> [anchor_id]

VAULT_PATH="$1"
DATE="$2"
CHECKPOINT_SUMMARY="$3"
ANCHOR_ID="$4"  # Optional: header anchor for deep linking (e.g., "~11:06am - Checkpoint (Pre-Compaction)")
TIME=$(date +"%l:%M%p" | tr '[:upper:]' '[:lower:]' | sed 's/^ //')  # e.g., "3:45pm"

DAILY_NOTE="$VAULT_PATH/journals/$DATE.md"

if [[ ! -f "$DAILY_NOTE" ]]; then
    echo "Daily note not found: $DAILY_NOTE" >&2
    exit 1
fi

# Find the Claude Sessions section and update checkpoint count
# Look for pattern like: - [[...|Daily Session: ...]] *(N checkpoints)* - ...
# Increment N

# Use perl for reliable in-place editing with complex regex
perl -i -pe '
    if (/\[\[.*daily-session.*\]\].*\*\((\d+) checkpoints?\)\*/) {
        my $count = $1 + 1;
        my $word = $count == 1 ? "checkpoint" : "checkpoints";
        s/\*\(\d+ checkpoints?\)\*/\*($count $word)\*/;
    }
' "$DAILY_NOTE"

# Also add the checkpoint summary as a nested bullet if provided
if [[ -n "$CHECKPOINT_SUMMARY" ]]; then
    # Find the daily session entry line number - must include checkpoint counter
    # This ensures we find the Claude Sessions entry, not other wiki-links to the transcript
    # Use -E for extended regex where ? means optional and \) escapes the paren
    SESSION_LINE=$(grep -En "daily-session-$DATE.*checkpoints?\\)" "$DAILY_NOTE" | head -1 | cut -d: -f1)

    if [[ -n "$SESSION_LINE" ]]; then
        # Find the last nested bullet (tab-indented line) after the session entry
        # We need to insert AFTER all existing nested bullets

        # Get total lines in file
        TOTAL_LINES=$(wc -l < "$DAILY_NOTE")

        # Find the line number to insert at (after last nested bullet or after session line)
        INSERT_AFTER=$SESSION_LINE

        # Look at lines after session entry to find last consecutive tab-indented line
        LINE_NUM=$((SESSION_LINE + 1))
        while [[ $LINE_NUM -le $TOTAL_LINES ]]; do
            LINE_CONTENT=$(sed -n "${LINE_NUM}p" "$DAILY_NOTE")
            # Check if line starts with tab (nested bullet)
            if [[ "$LINE_CONTENT" == $'\t'* ]]; then
                INSERT_AFTER=$LINE_NUM
                LINE_NUM=$((LINE_NUM + 1))
            else
                # No longer a nested bullet, stop looking
                break
            fi
        done

        # Format: 	- [[transcript#anchor|~TIME]]: Summary
        # If anchor provided, make the time a link to that section in the transcript
        INDENT=$'\t'
        TRANSCRIPT_PATH="ai-chats/transcripts/$DATE/daily-session-$DATE"

        if [[ -n "$ANCHOR_ID" ]]; then
            # Link to specific section: [[path#header|display text]]
            NESTED_BULLET="${INDENT}- [[${TRANSCRIPT_PATH}#${ANCHOR_ID}|~${TIME}]]: ${CHECKPOINT_SUMMARY}"
        else
            NESTED_BULLET="${INDENT}- ~${TIME}: ${CHECKPOINT_SUMMARY}"
        fi

        # Use sed to insert after the determined line
        sed -i '' "${INSERT_AFTER}a\\
${NESTED_BULLET}
" "$DAILY_NOTE"
    fi
fi

echo "Updated checkpoint count in $DAILY_NOTE"
