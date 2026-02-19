#!/bin/bash
# Combined safety hook: dangerous git commands + destructive deletion + bad practices
# Sources: Matt Pocock git-guardrails, zcaceres/claude-rm-rf, team requirements
# Hook type: PreToolUse (matcher: Bash) — exit 2 = block, exit 0 = allow
#
# Environment variables for experienced engineers (set in .claude/settings.local.json):
#   CLAUDE_SAFETY_ALLOW_PUSH=1  — allows git push (but still blocks push --force)
#   CLAUDE_SAFETY_ALLOW_FORCE_LEASE=1 — allows push --force-with-lease (for rebase workflows)
#   CLAUDE_SAFETY_ALLOW_BRANCH_DELETE=1 — allows git branch -D

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Exit early if no command
[[ -z "$COMMAND" ]] && exit 0

# Strip quoted strings to avoid false positives (e.g., echo "rm file")
STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

# === FORCE-WITH-LEASE (configurable — safe force push for rebase workflows) ===
# Must be checked BEFORE the --force block, since "push --force" is a substring of "push --force-with-lease"
if echo "$STRIPPED" | grep -qE -e "force-with-lease"; then
  if [[ "${CLAUDE_SAFETY_ALLOW_FORCE_LEASE:-}" == "1" ]]; then
    exit 0  # Allowed — safe force push
  else
    echo "BLOCKED: push --force-with-lease is restricted by the safety hook." >&2
    echo "Set CLAUDE_SAFETY_ALLOW_FORCE_LEASE=1 in .claude/settings.local.json env, or push manually." >&2
    exit 2
  fi
fi

# === ALWAYS-BLOCKED GIT COMMANDS (no bypass) ===
ALWAYS_BLOCK_PATTERNS=(
  "git reset --hard"
  "git clean -f"
  "git clean -fd"
  "git checkout \."
  "git restore \."
  "push --force"
  "reset --hard"
  "--no-verify"
)

for pattern in "${ALWAYS_BLOCK_PATTERNS[@]}"; do
  if echo "$STRIPPED" | grep -qE -e "$pattern"; then
    echo "BLOCKED: Dangerous git command detected: '$pattern'" >&2
    echo "If intentional, the user should run this manually outside Claude." >&2
    exit 2
  fi
done

# === CONFIGURABLE GIT COMMANDS (bypassable for experienced engineers) ===

# git push — blocked by default, allowed with CLAUDE_SAFETY_ALLOW_PUSH=1
if [[ "${CLAUDE_SAFETY_ALLOW_PUSH:-}" != "1" ]]; then
  if echo "$STRIPPED" | grep -qE -e "git push"; then
    echo "BLOCKED: git push is restricted by the safety hook." >&2
    echo "Run 'git push' manually, or set CLAUDE_SAFETY_ALLOW_PUSH=1 in .claude/settings.local.json env." >&2
    exit 2
  fi
fi

# git branch -D — blocked by default, allowed with CLAUDE_SAFETY_ALLOW_BRANCH_DELETE=1
if [[ "${CLAUDE_SAFETY_ALLOW_BRANCH_DELETE:-}" != "1" ]]; then
  if echo "$STRIPPED" | grep -qE -e "git branch -D"; then
    echo "BLOCKED: git branch -D is restricted by the safety hook." >&2
    echo "Use 'git branch -d' (safe delete) or set CLAUDE_SAFETY_ALLOW_BRANCH_DELETE=1 in .claude/settings.local.json env." >&2
    exit 2
  fi
fi

# === DESTRUCTIVE FILE DELETION ===
# Catch rm and all bypass variants (from zcaceres/claude-rm-rf)
DELETION_PATTERNS=(
  '\brm\b'
  '\bshred\b'
  '\bunlink\b'
  '/bin/rm'
  '/usr/bin/rm'
  '\./rm'
  'command rm'
  'env rm'
  '\\rm'
  'sudo rm'
  'xargs rm'
  'xargs.*rm'
  'find.*-delete'
  'find.*-exec.*rm'
)

# Allow: git rm (version-controlled, recoverable)
if echo "$STRIPPED" | grep -qE '\bgit rm\b'; then
  exit 0
fi

for pattern in "${DELETION_PATTERNS[@]}"; do
  if echo "$STRIPPED" | grep -qE -e "$pattern"; then
    echo "BLOCKED: Destructive file deletion detected." >&2
    echo "Use 'trash <file>' instead of 'rm' — files go to macOS Trash and are recoverable." >&2
    echo "Install: brew install trash" >&2
    exit 2
  fi
done

# === DATABASE DESTRUCTIVE COMMANDS ===
DB_PATTERNS=(
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE"
  "DELETE FROM.*WHERE 1"
  "DELETE FROM.*WITHOUT"
)

# Check against original COMMAND (not STRIPPED) since SQL is typically inside quotes
for pattern in "${DB_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE -e "$pattern"; then
    echo "BLOCKED: Destructive database command detected: '$pattern'" >&2
    echo "If intentional, the user should run this manually with explicit confirmation." >&2
    exit 2
  fi
done

exit 0
