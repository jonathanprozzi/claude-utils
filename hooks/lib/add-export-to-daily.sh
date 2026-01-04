#!/bin/bash
# Add export conversation entry to daily note's Claude Sessions section
# Usage: add-export-to-daily.sh <project> <topic> <summary_path> <description>
#
# Example:
#   add-export-to-daily.sh "Intuition Portal" "XState Refactor" \
#     "ai-chats/claude-code/intuition-portal/2025-12-11-0930-xstate-refactor-summary.md" \
#     "Transaction queue implementation, state machine fixes"

set -e

# Get script directory for lib imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared config
source "$SCRIPT_DIR/config.sh"

# Arguments
PROJECT="$1"
TOPIC="$2"
EXPORT_PATH="$3"  # Relative path from vault root (for wiki-link)
DESCRIPTION="$4"

# Sanitize description - strip <command-message> and <command-name> tags (and their content)
if [[ -n "$DESCRIPTION" ]]; then
    DESCRIPTION=$(echo "$DESCRIPTION" | sed -E 's/<command-(message|name)>[^<]*<\/command-(message|name)>//g')
    # Clean up any trailing " - " or extra whitespace left behind
    DESCRIPTION=$(echo "$DESCRIPTION" | sed -E 's/[[:space:]]*-[[:space:]]*$//; s/^[[:space:]]+//; s/[[:space:]]+$//')
fi

if [[ -z "$PROJECT" || -z "$TOPIC" || -z "$EXPORT_PATH" ]]; then
    echo "Usage: add-export-to-daily.sh <project> <topic> <export_path> [description]" >&2
    echo "  project:     Project name (e.g., 'Intuition Portal')" >&2
    echo "  topic:       Brief topic (e.g., 'XState Refactor')" >&2
    echo "  export_path: Relative path from vault root for wiki-link" >&2
    echo "  description: Optional brief description" >&2
    exit 1
fi

# Get vault path
VAULT_PATH=$(get_vault_path)

if [[ -z "$VAULT_PATH" ]]; then
    echo "No vault path configured. Set obsidian_vault_path in $CONFIG_FILE" >&2
    exit 1
fi

# Get today's date and time
DATE=$(date +%Y-%m-%d)
TIME=$(date +"%l:%M%p" | tr '[:upper:]' '[:lower:]' | sed 's/^ //')  # e.g., "9:30am"
HOUR=$(date +%H)

DAILY_NOTE="$VAULT_PATH/journals/$DATE.md"

# Late-night edge case: if today's note doesn't exist and it's before 6am,
# fall back to yesterday's note (session likely started previous day)
if [[ ! -f "$DAILY_NOTE" ]]; then
    if [[ $HOUR -lt 6 ]]; then
        YESTERDAY=$(date -v-1d +%Y-%m-%d)
        YESTERDAY_NOTE="$VAULT_PATH/journals/$YESTERDAY.md"
        if [[ -f "$YESTERDAY_NOTE" ]]; then
            echo "Today's daily note not found, using yesterday's note (late-night session)" >&2
            DAILY_NOTE="$YESTERDAY_NOTE"
        else
            echo "Daily note not found: $DAILY_NOTE (also checked $YESTERDAY_NOTE)" >&2
            exit 1
        fi
    else
        echo "Daily note not found: $DAILY_NOTE" >&2
        exit 1
    fi
fi

# Remove .md extension from path for wiki-link (Obsidian convention)
LINK_PATH="${EXPORT_PATH%.md}"

# Build the entry
# Format: - ~HH:MMam - [[path|Project: Topic]] - Description
if [[ -n "$DESCRIPTION" ]]; then
    ENTRY="- ~${TIME} - [[${LINK_PATH}|${PROJECT}: ${TOPIC}]] - ${DESCRIPTION}"
else
    ENTRY="- ~${TIME} - [[${LINK_PATH}|${PROJECT}: ${TOPIC}]]"
fi

# Check if Claude Sessions section exists
if grep -q "## Claude Sessions" "$DAILY_NOTE"; then
    # Find the line number of Claude Sessions header
    SECTION_LINE=$(grep -n "## Claude Sessions" "$DAILY_NOTE" | head -1 | cut -d: -f1)

    # Find where to insert (after any existing entries, before next section or blank line pattern)
    # Look for entries that start with "- " after the section header
    TOTAL_LINES=$(wc -l < "$DAILY_NOTE")
    INSERT_AFTER=$SECTION_LINE

    # Skip the header line and any comment lines
    LINE_NUM=$((SECTION_LINE + 1))
    while [[ $LINE_NUM -le $TOTAL_LINES ]]; do
        LINE_CONTENT=$(sed -n "${LINE_NUM}p" "$DAILY_NOTE")

        # Skip HTML comments
        if [[ "$LINE_CONTENT" == "<!--"* ]]; then
            INSERT_AFTER=$LINE_NUM
            LINE_NUM=$((LINE_NUM + 1))
            continue
        fi

        # If it's a session entry (starts with "- "), track it
        if [[ "$LINE_CONTENT" == "- "* ]]; then
            INSERT_AFTER=$LINE_NUM
            LINE_NUM=$((LINE_NUM + 1))
            # Also skip any nested bullets (tab-indented)
            while [[ $LINE_NUM -le $TOTAL_LINES ]]; do
                NESTED_LINE=$(sed -n "${LINE_NUM}p" "$DAILY_NOTE")
                if [[ "$NESTED_LINE" == $'\t'* ]]; then
                    INSERT_AFTER=$LINE_NUM
                    LINE_NUM=$((LINE_NUM + 1))
                else
                    break
                fi
            done
            continue
        fi

        # If it's a placeholder entry, we'll replace after it
        if [[ "$LINE_CONTENT" == "- _["* ]]; then
            INSERT_AFTER=$LINE_NUM
            LINE_NUM=$((LINE_NUM + 1))
            continue
        fi

        # Empty line or next section - stop here
        break
    done

    # Insert the new entry after the determined line
    sed -i '' "${INSERT_AFTER}a\\
${ENTRY}
" "$DAILY_NOTE"

else
    # Claude Sessions section doesn't exist - create it
    # Try to insert after "## Notes and Ideas" section, or before "## Seeds for Publishing"

    if grep -q "## Seeds for Publishing" "$DAILY_NOTE"; then
        # Insert before Seeds for Publishing
        SEEDS_LINE=$(grep -n "## Seeds for Publishing" "$DAILY_NOTE" | head -1 | cut -d: -f1)

        # Create the section with the entry
        SECTION_CONTENT="## Claude Sessions
<!-- Linked summaries: key points + link to full transcript -->
${ENTRY}

"
        # Insert before the Seeds line
        sed -i '' "$((SEEDS_LINE))i\\
${SECTION_CONTENT}
" "$DAILY_NOTE"
    else
        # Append to end of file
        echo "" >> "$DAILY_NOTE"
        echo "## Claude Sessions" >> "$DAILY_NOTE"
        echo "<!-- Linked summaries: key points + link to full transcript -->" >> "$DAILY_NOTE"
        echo "$ENTRY" >> "$DAILY_NOTE"
    fi
fi

echo "Added export entry to $DAILY_NOTE"
echo "  Entry: $ENTRY"
