#!/bin/bash
# Setup script for claude-utils
# Configures vault paths and installs commands

set -e

CONFIG_DIR="$HOME/.config/claude-code-workflow"
CONFIG_FILE="$CONFIG_DIR/config.json"
CLAUDE_COMMANDS="$HOME/.claude/commands"

echo "=== Claude Utils Setup ==="
echo ""

# Create config directory
mkdir -p "$CONFIG_DIR"
mkdir -p "$CLAUDE_COMMANDS"

# Get vault path
echo "Enter your Obsidian vault path (where your daily notes live):"
echo "  Example: /Users/you/Documents/my-vault"
echo ""
read -p "Vault path: " vault_path

# Expand tilde if present
vault_path="${vault_path/#\~/$HOME}"

# Validate path
if [[ ! -d "$vault_path" ]]; then
    echo "Warning: Directory does not exist. Create it? (y/n)"
    read -p "> " create_dir
    if [[ "$create_dir" == "y" ]]; then
        mkdir -p "$vault_path"
        echo "Created: $vault_path"
    else
        echo "Please create the directory and run setup again."
        exit 1
    fi
fi

# Create required vault subdirectories
echo ""
echo "Creating vault structure..."
mkdir -p "$vault_path/journals"
mkdir -p "$vault_path/ai-chats/transcripts"
mkdir -p "$vault_path/ai-chats/claude-code"
mkdir -p "$vault_path/templates"
echo "  ✓ journals/"
echo "  ✓ ai-chats/transcripts/"
echo "  ✓ ai-chats/claude-code/"
echo "  ✓ templates/"

# Write config
echo ""
echo "Writing configuration..."
cat > "$CONFIG_FILE" << EOF
{
  "obsidian_vault_path": "$vault_path",
  "lastUsed": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
echo "  ✓ $CONFIG_FILE"

# Install commands
echo ""
echo "Installing commands..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for cmd in "$SCRIPT_DIR/commands/"*.md; do
    if [[ -f "$cmd" ]]; then
        name=$(basename "$cmd")
        cp "$cmd" "$CLAUDE_COMMANDS/$name"
        echo "  ✓ $name"
    fi
done

# Copy daily journal template
echo ""
echo "Installing templates..."
if [[ -f "$SCRIPT_DIR/templates/obsidian/daily-journal.md" ]]; then
    cp "$SCRIPT_DIR/templates/obsidian/daily-journal.md" "$vault_path/templates/Daily Journal Template.md"
    echo "  ✓ Daily Journal Template.md"
fi

# Copy hooks and library scripts
echo ""
echo "Installing hooks..."
mkdir -p "$HOME/.config/claude-code/hooks/lib"

for hook in "$SCRIPT_DIR/hooks/"*.sh; do
    if [[ -f "$hook" ]]; then
        name=$(basename "$hook")
        cp "$hook" "$HOME/.config/claude-code/hooks/$name"
        chmod +x "$HOME/.config/claude-code/hooks/$name"
        echo "  ✓ hooks/$name"
    fi
done

for lib in "$SCRIPT_DIR/hooks/lib/"*.sh; do
    if [[ -f "$lib" ]]; then
        name=$(basename "$lib")
        cp "$lib" "$HOME/.config/claude-code/hooks/lib/$name"
        chmod +x "$HOME/.config/claude-code/hooks/lib/$name"
        echo "  ✓ hooks/lib/$name"
    fi
done

# Copy parse-transcript.py if available
if [[ -f "$SCRIPT_DIR/scripts/parse-transcript.py" ]]; then
    cp "$SCRIPT_DIR/scripts/parse-transcript.py" "$HOME/.config/claude-code/hooks/lib/"
    chmod +x "$HOME/.config/claude-code/hooks/lib/parse-transcript.py"
    echo "  ✓ hooks/lib/parse-transcript.py"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Open a new Claude Code session"
echo "  2. Navigate to your vault: cd $vault_path"
echo "  3. Run /daily-session to start"
echo ""
echo "Available commands:"
echo "  /daily-session     - Start a daily thinking session"
echo "  /checkpoint        - Create a checkpoint"
echo "  /end-day           - End the day with a handoff"
echo "  /export-conversation - Export any session"
echo ""
