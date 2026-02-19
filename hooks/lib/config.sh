#!/bin/bash
# Shared config loader for Claude Code hooks and Smart Zone
# Source this file to get access to config values

# ============================================================================
# Legacy config (claude-code-workflow)
# ============================================================================
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

# ============================================================================
# Smart Zone config
# Config loading order (aligned with claude-hud pattern):
# 1. Plugin dir config/config.yaml (bundled/dotfiles users)
# 2. ~/.claude/plugins/smart-zone/config.yaml (standard installs)
# 3. Env vars (quick override)
# 4. Defaults
# ============================================================================

# Get script directory to find plugin dir
_get_plugin_dir() {
    local script_path="${BASH_SOURCE[0]}"
    local lib_dir="$(cd "$(dirname "$script_path")" && pwd)"
    # Go up from hooks/lib to plugin root
    echo "$(cd "$lib_dir/../.." && pwd)"
}

SMART_ZONE_PLUGIN_DIR="$(_get_plugin_dir)"
SMART_ZONE_STANDARD_CONFIG="$HOME/.claude/plugins/smart-zone/config.yaml"
SMART_ZONE_BUNDLED_CONFIG="$SMART_ZONE_PLUGIN_DIR/config/config.yaml"

# Find the active config file (first that exists)
get_smart_zone_config_path() {
    if [[ -f "$SMART_ZONE_BUNDLED_CONFIG" ]]; then
        echo "$SMART_ZONE_BUNDLED_CONFIG"
    elif [[ -f "$SMART_ZONE_STANDARD_CONFIG" ]]; then
        echo "$SMART_ZONE_STANDARD_CONFIG"
    else
        echo ""  # No config file found
    fi
}

# Read a value from Smart Zone YAML config
# Usage: get_smart_zone_config "threshold" [default]
# Usage: get_smart_zone_config "carry_forward.source" [default]
# Requires: yq (brew install python-yq)
get_smart_zone_config() {
    local key="$1"
    local default="${2:-}"
    local config_path=$(get_smart_zone_config_path)

    if [[ -n "$config_path" && -f "$config_path" ]]; then
        # Use yq to parse YAML - convert dot notation to yq path
        # e.g., "carry_forward.source" -> ".carry_forward.source"
        local yq_path=".${key}"
        local value=$(yq -r "$yq_path // empty" "$config_path" 2>/dev/null)
        if [[ -n "$value" && "$value" != "null" ]]; then
            echo "$value"
            return
        fi
    fi
    echo "$default"
}

# Get Smart Zone threshold with full fallback chain
# 1. Env var SMART_ZONE_THRESHOLD
# 2. Config file threshold
# 3. Default: 40
get_smart_zone_threshold() {
    # Check env var first (highest priority for quick override)
    if [[ -n "$SMART_ZONE_THRESHOLD" ]]; then
        echo "$SMART_ZONE_THRESHOLD"
        return
    fi

    # Check config file
    local config_threshold=$(get_smart_zone_config "threshold")
    if [[ -n "$config_threshold" ]]; then
        echo "$config_threshold"
        return
    fi

    # Default
    echo "40"
}

# Check if threshold is custom (non-default)
is_smart_zone_custom() {
    local threshold=$(get_smart_zone_threshold)
    local default_threshold=40

    # Check if env var is set OR config file exists with non-default value
    if [[ -n "$SMART_ZONE_THRESHOLD" ]]; then
        echo "1"
    elif [[ -n "$(get_smart_zone_config_path)" ]]; then
        local config_threshold=$(get_smart_zone_config "threshold")
        if [[ -n "$config_threshold" && "$config_threshold" != "$default_threshold" ]]; then
            echo "1"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# Get carry-forward note path
get_carry_forward_source() {
    local source=$(get_smart_zone_config "carry_forward.source")
    # Expand ~ to $HOME
    echo "${source/#\~/$HOME}"
}

# Get carry-forward section header
get_carry_forward_section() {
    get_smart_zone_config "carry_forward.section" "## Carry Forward"
}

# Get post-compact action
get_carry_forward_post_compact() {
    get_smart_zone_config "carry_forward.post_compact" "keep"
}

# Export for convenience
export CONFIG_FILE
export SMART_ZONE_PLUGIN_DIR
export SMART_ZONE_STANDARD_CONFIG
export SMART_ZONE_BUNDLED_CONFIG
