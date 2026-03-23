#!/bin/bash
# PostToolUse hook: auto-track high-signal work events
# Watches for git commits, file creation, and MCP writes to external systems.
# Ignores reads, searches, and other low-signal operations.
#
# Input: JSON on stdin with tool_name, tool_input, tool_output fields

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
TRACKER="$LIB_DIR/track-accomplishment.sh"

if [[ ! -x "$TRACKER" ]]; then
    exit 0
fi

# Read the hook input from stdin
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_name', ''))
except:
    print('')
" 2>/dev/null)

# Skip if we can't parse or tool is empty
if [[ -z "$TOOL_NAME" ]]; then
    exit 0
fi

# Extract tool input for pattern matching
TOOL_INPUT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    ti = data.get('tool_input', {})
    if isinstance(ti, dict):
        print(json.dumps(ti))
    else:
        print(str(ti))
except:
    print('')
" 2>/dev/null)

case "$TOOL_NAME" in
    Bash)
        # Check for git commit
        COMMAND=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('command', ''))
except:
    print('')
" 2>/dev/null)

        if echo "$COMMAND" | grep -q "git commit"; then
            # Extract commit message (macOS-compatible, uses sed instead of grep -P)
            MSG=$(echo "$COMMAND" | sed -n 's/.*-m ["'"'"']\([^"'"'"']*\)["'"'"'].*/\1/p' 2>/dev/null)
            if [[ -z "$MSG" ]]; then
                MSG=$(echo "$COMMAND" | head -c 120)
            fi
            "$TRACKER" "git_commit" "$MSG" ""
        fi
        ;;

    Write)
        # New file created
        FILEPATH=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('file_path', ''))
except:
    print('')
" 2>/dev/null)

        if [[ -n "$FILEPATH" ]]; then
            FILENAME=$(basename "$FILEPATH")
            "$TRACKER" "file_create" "Created $FILENAME" "$FILEPATH"
        fi
        ;;

    mcp__claude_ai_Notion__notion-create-pages)
        # Notion page created
        TITLE=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    pages = data.get('pages', [])
    if pages:
        props = pages[0].get('properties', {})
        title = props.get('title', props.get('', 'Untitled'))
        print(title)
    else:
        print('Notion page')
except:
    print('Notion page')
" 2>/dev/null)
        "$TRACKER" "mcp_write" "Created Notion page: $TITLE" ""
        ;;

    mcp__claude_ai_HubSpot__manage_crm_objects)
        "$TRACKER" "mcp_write" "Updated HubSpot CRM records" ""
        ;;

    mcp__claude_ai_Linear__save_issue|mcp__linear-server__save_issue)
        ISSUE_TITLE=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('title', 'Linear issue'))
except:
    print('Linear issue')
" 2>/dev/null)
        "$TRACKER" "mcp_write" "Created/updated Linear issue: $ISSUE_TITLE" ""
        ;;

    Skill)
        SKILL_NAME=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('skill', ''))
except:
    print('')
" 2>/dev/null)
        if [[ -n "$SKILL_NAME" ]]; then
            "$TRACKER" "skill_run" "Ran /$SKILL_NAME" ""
        fi
        ;;

    *)
        # Ignore everything else (Read, Glob, Grep, Edit, searches, etc.)
        ;;
esac

exit 0
