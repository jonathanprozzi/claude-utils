#!/bin/bash
# Track an accomplishment to the daily JSONL log
# Usage: track-accomplishment.sh <type> <summary> [detail]
#
# Types: session_start, checkpoint, compaction, git_commit, mcp_write,
#        file_create, file_edit, skill_run
#
# Appends to: $VAULT_PATH/daily-gn/.tracking/YYYY-MM-DD.jsonl

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

TYPE="${1:-unknown}"
SUMMARY="${2:-}"
DETAIL="${3:-}"

if [[ -z "$SUMMARY" ]]; then
    exit 0
fi

VAULT_PATH=$(get_vault_path)
if [[ -z "$VAULT_PATH" ]]; then
    exit 0
fi

DATE=$(date +"%Y-%m-%d")
TIME=$(date +"%H:%M")
TRACKING_DIR="$VAULT_PATH/daily-gn/.tracking"

mkdir -p "$TRACKING_DIR"

# Escape strings for JSON
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/}"
    s="${s//$'\t'/\\t}"
    echo "$s"
}

ESCAPED_SUMMARY=$(json_escape "$SUMMARY")
ESCAPED_DETAIL=$(json_escape "$DETAIL")

echo "{\"time\":\"$TIME\",\"type\":\"$TYPE\",\"summary\":\"$ESCAPED_SUMMARY\",\"detail\":\"$ESCAPED_DETAIL\"}" >> "$TRACKING_DIR/$DATE.jsonl"
