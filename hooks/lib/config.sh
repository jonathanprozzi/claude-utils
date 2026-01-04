#!/bin/bash
# Shared config loader for Claude Code hooks
# Source this file to get access to config values

CONFIG_FILE="$HOME/.config/claude-code-workflow/config.json"

# Read a value from the config file
# Usage: get_config "key"
get_config() {
    local key="$1"
    if [[ -f "$CONFIG_FILE" ]]; then
        python3 -c "
import json
with open('$CONFIG_FILE') as f:
    config = json.load(f)
print(config.get('$key', ''))
" 2>/dev/null
    fi
}

# Get vault path with fallbacks:
# 1. Config file (primary)
# 2. Environment variable (legacy)
# 3. CWD detection (if has transcript structure)
get_vault_path() {
    local cwd="${1:-$(pwd)}"

    # Try config file first
    local vault_path=$(get_config "obsidian_vault_path")

    # Fallback to env var
    if [[ -z "$vault_path" ]]; then
        vault_path="${OBSIDIAN_VAULT_PATH:-}"
    fi

    # Fallback to CWD detection
    if [[ -z "$vault_path" && -d "$cwd/ai-chats/transcripts" ]]; then
        vault_path="$cwd"
    fi

    echo "$vault_path"
}

# Export for convenience
export CONFIG_FILE
