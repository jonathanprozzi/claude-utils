#!/bin/bash
# PreCompact Hook: Auto-checkpoint before context compaction
# This script runs BEFORE Claude compacts the session context
# It creates a checkpoint in the daily session transcript

set -e

# Get script directory for lib imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Load shared config
source "$LIB_DIR/config.sh"

# Read hook input from stdin
INPUT=$(cat)

# Parse JSON input using python (more reliable than jq which might not be installed)
parse_json() {
    echo "$INPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('$1', ''))
"
}

TRANSCRIPT_PATH=$(parse_json "transcript_path")
CWD=$(parse_json "cwd")
TRIGGER=$(parse_json "trigger")  # "manual" or "auto"
SESSION_ID=$(parse_json "session_id")

# Determine vault path using config helper (reads from config file with fallbacks)
VAULT_PATH=$(get_vault_path "$CWD")

# If still no vault path, exit gracefully (not in a daily session context)
if [[ -z "$VAULT_PATH" ]]; then
    echo '{"status": "skipped", "reason": "No vault path configured"}'
    exit 0
fi

# Get today's date
DATE=$(date +%Y-%m-%d)
TIME=$(date +"%l:%M%p" | tr '[:upper:]' '[:lower:]' | sed 's/^ //')  # e.g., "3:45pm"

# Check if today's daily session transcript exists
DAILY_TRANSCRIPT="$VAULT_PATH/ai-chats/transcripts/$DATE/daily-session-$DATE.md"

if [[ ! -f "$DAILY_TRANSCRIPT" ]]; then
    echo "{\"status\": \"skipped\", \"reason\": \"No daily session transcript for today\"}"
    exit 0
fi

# Parse Claude's JSONL transcript to get conversation summary
SUMMARY_JSON=$("$LIB_DIR/parse-transcript.py" "$TRANSCRIPT_PATH" 2>/dev/null || echo '{}')

# Extract key info from summary using python (use | as delimiter to handle spaces)
IFS='|' read -r MESSAGE_COUNT SESSION_TYPE FILES_CREATED FILES_MODIFIED TOOL_CALLS <<< $(echo "$SUMMARY_JSON" | python3 -c "
import json,sys
d=json.load(sys.stdin)
ts = d.get('tool_summary', {})
print(d.get('message_count', 0), end='|')
print(d.get('session_type', 'Unknown'), end='|')
print(ts.get('files_created', 0), end='|')
print(ts.get('files_modified', 0), end='|')
print(ts.get('total_tool_calls', 0))
")

# Extract activities list
ACTIVITIES=$(echo "$SUMMARY_JSON" | python3 -c "
import json,sys
d=json.load(sys.stdin)
activities = d.get('activities', [])
for a in activities[:6]:
    print(f'- {a}')
" 2>/dev/null)

# Extract user topics (now with wiki-links from parser)
USER_TOPICS=$(echo "$SUMMARY_JSON" | python3 -c "
import json,sys
d=json.load(sys.stdin)
topics = d.get('user_topics', [])
for t in topics[:5]:  # Show more topics
    print(f'- {t}')
" 2>/dev/null)

# Archive full transcript FIRST (so we can link to it in checkpoint)
ARCHIVE_DIR="$VAULT_PATH/ai-chats/transcripts/$DATE/archives"
mkdir -p "$ARCHIVE_DIR"

# Generate timestamp for archive filename
ARCHIVE_TIMESTAMP=$(date +%H%M)

# Copy JSONL file
if [[ -f "$TRANSCRIPT_PATH" ]]; then
    cp "$TRANSCRIPT_PATH" "$ARCHIVE_DIR/session-$DATE-$ARCHIVE_TIMESTAMP.jsonl"
fi

# Export full transcript to Markdown
MARKDOWN_ARCHIVE="$ARCHIVE_DIR/session-$DATE-$ARCHIVE_TIMESTAMP-full.md"
"$LIB_DIR/parse-transcript.py" "$TRANSCRIPT_PATH" --export-markdown "$MARKDOWN_ARCHIVE" 2>/dev/null || true

# Create relative path for Obsidian wiki-link (from vault root)
ARCHIVE_LINK="ai-chats/transcripts/$DATE/archives/session-$DATE-$ARCHIVE_TIMESTAMP-full"

# Create checkpoint entry with structured data (including archive link)
CHECKPOINT_ENTRY="### ~$TIME - Checkpoint (Pre-Compaction)
Context auto-saved before compaction ($TRIGGER trigger). [[${ARCHIVE_LINK}|Full transcript]]

**Session:** $SESSION_TYPE | $MESSAGE_COUNT messages | $TOOL_CALLS tool calls | $FILES_CREATED created | $FILES_MODIFIED modified

**Key Activities:**
$ACTIVITIES

**User Requests:**
$USER_TOPICS

---
"

# Find where to insert checkpoint (before "## Session Handoff" or at end of Session Log)
if grep -q "## Session Handoff" "$DAILY_TRANSCRIPT"; then
    # Insert before Session Handoff section
    # Use perl for reliable multi-line insertion
    perl -i -pe "
        if (/^## Session Handoff/ && !\$done) {
            print \"$CHECKPOINT_ENTRY\n\";
            \$done = 1;
        }
    " "$DAILY_TRANSCRIPT"
else
    # Append to end of file (before Tags section if it exists)
    if grep -q "^## Tags" "$DAILY_TRANSCRIPT"; then
        perl -i -pe "
            if (/^## Tags/ && !\$done) {
                print \"$CHECKPOINT_ENTRY\n\";
                \$done = 1;
            }
        " "$DAILY_TRANSCRIPT"
    else
        echo "" >> "$DAILY_TRANSCRIPT"
        echo "$CHECKPOINT_ENTRY" >> "$DAILY_TRANSCRIPT"
    fi
fi

# Generate brief summary for daily note bullet
# Format: "Pre-compaction (N msgs). Session type - key topic"
KEY_TOPIC=$(echo "$SUMMARY_JSON" | python3 -c "
import json,sys,re
d=json.load(sys.stdin)

# Common greetings to skip when finding meaningful topics
GREETINGS = {
    'gm', 'gm claude', 'gm!', 'good morning', 'good morning claude',
    'hi', 'hi claude', 'hello', 'hello claude', 'hey', 'hey claude',
    'hi there', 'hello there', 'thanks', 'thank you', 'ty',
}

# Try to extract a meaningful topic from user requests
topics = d.get('user_topics', [])
for topic in topics:
    # Strip XML tags and wiki-link formatting for comparison
    clean = re.sub(r'<[^>]+>', '', topic)  # Remove XML/HTML tags
    clean = re.sub(r'\[\[([^\]|]+)(\|[^\]]+)?\]\]', r'\1', clean)
    # Get first meaningful phrase
    match = re.match(r'^([^.!?,;:]+)', clean)
    if match:
        phrase = match.group(1).strip()
        # Skip greetings
        if phrase.lower() in GREETINGS:
            continue
        # Skip very short phrases (likely greetings or acknowledgments)
        if len(phrase) < 10:
            continue
        # Truncate if too long
        if len(phrase) > 50:
            phrase = phrase[:47] + '...'
        print(phrase)
        sys.exit(0)

# Fallback: try to get a project name from activities
activities = d.get('activities', [])
for act in activities:
    # Look for project-like paths
    if '/intuition/' in act.lower():
        print('Intuition work')
        sys.exit(0)
    if '/seeds/' in act.lower():
        print('Vault/workflow updates')
        sys.exit(0)
    if '/dotfiles/' in act.lower():
        print('Tooling updates')
        sys.exit(0)

# No meaningful topic found
print('')
" 2>/dev/null)

# Build summary: include session type and key topic if available
if [[ -n "$KEY_TOPIC" ]]; then
    CHECKPOINT_SUMMARY="Pre-compaction ($MESSAGE_COUNT msgs). $SESSION_TYPE - $KEY_TOPIC"
else
    CHECKPOINT_SUMMARY="Pre-compaction ($MESSAGE_COUNT msgs). $SESSION_TYPE"
fi

# Create anchor ID for deep linking (matches the checkpoint header in transcript)
# Header: ### ~11:06am - Checkpoint (Pre-Compaction)
ANCHOR_ID="~${TIME} - Checkpoint (Pre-Compaction)"

# Update checkpoint count in daily note (with anchor for deep linking)
"$LIB_DIR/update-checkpoint-count.sh" "$VAULT_PATH" "$DATE" "$CHECKPOINT_SUMMARY" "$ANCHOR_ID" 2>/dev/null || true

# Output success status
echo "{\"status\": \"success\", \"checkpoint_time\": \"$TIME\", \"trigger\": \"$TRIGGER\", \"messages\": $MESSAGE_COUNT, \"archive\": \"$ARCHIVE_DIR\"}"
exit 0
