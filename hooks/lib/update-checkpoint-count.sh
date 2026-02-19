#!/bin/bash
# Update checkpoint count in daily note's Claude Sessions section
# Usage: update-checkpoint-count.sh <vault_path> <date_yyyy_mm_dd> <checkpoint_summary> [anchor_id] [notes_created]

VAULT_PATH="$1"
DATE="$2"
CHECKPOINT_SUMMARY="$3"
ANCHOR_ID="$4"  # Optional: header anchor for deep linking (e.g., "~11:06am - Checkpoint (Pre-Compaction)")
NOTES_CREATED="$5"  # Optional: newline-separated list of note names created this checkpoint
TIME=$(date +"%l:%M%p" | tr '[:upper:]' '[:lower:]' | sed 's/^ //')  # e.g., "3:45pm"

DAILY_NOTE="$VAULT_PATH/journals/$DATE.md"
LOG_FILE="${VAULT_PATH}/ai-chats/transcripts/$DATE/hook-debug.log"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

if [[ ! -f "$DAILY_NOTE" ]]; then
    echo "Daily note not found: $DAILY_NOTE" >&2
    exit 1
fi

# Find the Claude Sessions section and update checkpoint count
# Look for pattern like: - [[...|Daily Session: ...]] *(N checkpoints)* - ...
# Increment N, or add *(1 checkpoint)* if no counter exists yet

# First check if the counter already exists
if grep -q "daily-session-$DATE.*checkpoints\?)" "$DAILY_NOTE"; then
    # Counter exists — increment it
    perl -i -pe '
        if (/\[\[.*daily-session.*\]\].*\*\((\d+) checkpoints?\)\*/) {
            my $count = $1 + 1;
            my $word = $count == 1 ? "checkpoint" : "checkpoints";
            s/\*\(\d+ checkpoints?\)\*/\*($count $word)\*/;
        }
    ' "$DAILY_NOTE"
else
    # No counter yet (first compaction) — add *(1 checkpoint)* after the ]] of the daily session link
    perl -i -pe '
        if (/\[\[.*daily-session-'"$DATE"'.*?\]\]/ && !/checkpoints?\)/) {
            s/(\[\[.*daily-session-'"$DATE"'.*?\]\])/$1 *(1 checkpoint)*/;
        }
    ' "$DAILY_NOTE"
fi

# Also add the checkpoint summary as a nested bullet if provided
if [[ -n "$CHECKPOINT_SUMMARY" ]]; then
    # Find the daily session entry line number
    # Try with checkpoint counter first (normal case), fall back to just the transcript link
    SESSION_LINE=$(grep -En "daily-session-$DATE.*checkpoints?\\)" "$DAILY_NOTE" | head -1 | cut -d: -f1)
    if [[ -z "$SESSION_LINE" ]]; then
        SESSION_LINE=$(grep -En "daily-session-$DATE" "$DAILY_NOTE" | head -1 | cut -d: -f1)
    fi

    echo "[$(date +%H:%M:%S)] update-checkpoint: SESSION_LINE=$SESSION_LINE, NOTES_CREATED=$(echo "$NOTES_CREATED" | wc -l | tr -d ' ') notes" >> "$LOG_FILE"

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

        # Build the full insertion: checkpoint bullet + optional notes created
        FULL_INSERT="$NESTED_BULLET"

        # Append notes-created bullets if provided
        if [[ -n "$NOTES_CREATED" ]]; then
            DOUBLE_INDENT=$'\t\t'
            FULL_INSERT="${FULL_INSERT}
${INDENT}- **Notes created:**"
            while IFS= read -r NOTE_NAME; do
                [[ -z "$NOTE_NAME" ]] && continue
                FULL_INSERT="${FULL_INSERT}
${DOUBLE_INDENT}- [[${NOTE_NAME}]]"
            done <<< "$NOTES_CREATED"
        fi

        # Use python3 for reliable multi-line insertion
        # (macOS sed fails on multi-line content with tabs — "invalid command code")
        INSERT_FILE=$(mktemp)
        printf '%s\n' "$FULL_INSERT" > "$INSERT_FILE"

        python3 -c "
import sys

daily_note = sys.argv[1]
insert_file = sys.argv[2]
insert_after = int(sys.argv[3])  # 1-indexed line number

with open(insert_file, 'r') as f:
    insert_content = f.read()

with open(daily_note, 'r') as f:
    lines = f.readlines()

# Insert content after the target line (convert to 0-indexed)
lines.insert(insert_after, insert_content)

with open(daily_note, 'w') as f:
    f.writelines(lines)
" "$DAILY_NOTE" "$INSERT_FILE" "$INSERT_AFTER" 2>>"$LOG_FILE"

        if [[ $? -ne 0 ]]; then
            echo "ERROR: python3 insertion failed for $DAILY_NOTE at line $INSERT_AFTER" >> "$LOG_FILE"
        fi

        # Clean up temp file
        [[ -f "$INSERT_FILE" ]] && command rm -f "$INSERT_FILE"
    fi
fi

echo "Updated checkpoint count in $DAILY_NOTE"
