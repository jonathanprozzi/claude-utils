---
disable-model-invocation: true
---

Create a comprehensive markdown export of this conversation session with enhanced frontmatter for knowledge graph integration.

## Command Usage:
- `/export-conversation` - Export using saved preferences (default: comprehensive format)
- `/export-conversation -f` or `--full` - Export full transcript with all tool calls
- `/export-conversation -s` or `--summary` - Export detailed summary only
- `/export-conversation -b` or `--both` - Export both summary and full transcript
- `/export-conversation -n` or `--no-update` - Skip daily note integration
- `/export-conversation --no-prompt` - Skip all prompts, use saved defaults

**Flags can be combined:** `/export-conversation -b` (both + daily note update), `/export-conversation -bn` (both, skip daily note)

## Configuration & Directory Selection

First, check for config at `~/.config/claude-code-workflow/config.json` (primary) or `~/.claude/export-conversation-config.json` (legacy):

Based on the result:

1. **If no config or savedDirectory is empty**:
   - Ask: "Where would you like to save conversation exports? Options:
     - Press Enter for current directory (one-time)
     - Type a path to save there and remember for future exports
     - Type 'obsidian' to browse common Obsidian vault locations"

2. **If savedDirectory exists in config**:
   - Ask: "Export to saved location: [savedDirectory]? Options:
     - Press Enter to use saved location
     - Type 'current' to use current directory (one-time)
     - Type a new path to change saved location
     - Type 'forget' to clear saved preference"

## Save Configuration

When user provides a new directory path:
1. Verify the directory exists or create it
2. Save the preference to `~/.config/claude-code-workflow/config.json`:
   ```json
   {
     "savedDirectory": "USER_PROVIDED_PATH",
     "obsidian_vault_path": "/path/to/vault",
     "lastUsed": "CURRENT_DATE"
   }
   ```
3. For 'forget': remove the savedDirectory key from config

## Project Detection

Detect project context for frontmatter:

1. **Check current `.git` directory** → use repo name as `project`
2. **Scan parent directories** for `.git` → use that repo name
3. **Check saved projectMemory** in config → reuse last choice for this path
4. **Fallback** to directory name
5. **Detect umbrella** from project name patterns:
   - `intuition-*` → umbrella: `intuition`
   - `hats-*` → umbrella: `hats`
   - Or ask user if unclear

## Smart Filename Generation

Generate a descriptive filename:
1. Current timestamp: `YYYY-MM-DD-HHMM` format
2. Topic summary: 3-4 words from conversation, kebab-case
3. Example: `2025-12-02-1430-xstate-transaction-queue.md`
4. For `-b` (both): append `-summary.md` and `-transcript.md`

## Export Content Structure

### YAML Frontmatter (Required for ALL exports)

Both summary and transcript exports MUST include this frontmatter:

```yaml
---
date: YYYY-MM-DD
source: claude-code
project: {detected project name}
umbrella: {parent grouping if applicable}
session_name: {conversation/session name if renamed, null if default}
session_type: engineering
tags: [{auto-detected from content}]
files_touched:
  - path/to/file1.ext
  - path/to/file2.ext
message_count: N
duration: {approximate session duration}
working_directory: {path}
git_branch: {if applicable}
---
```

**Frontmatter field guidelines:**
- `project`: From git detection or user input
- `umbrella`: Groups related projects (intuition, hats, personal)
- `session_name`: The conversation name (from `/rename` or session title). If the session was renamed, use that name. This creates traceability between exported transcripts and the notes/artifacts produced during the session. Omit or set to null if using the default unnamed session.
- `session_type`: `engineering` | `debugging` | `refactoring` | `research` | `planning`
- `tags`: Extract from content - languages, frameworks, concepts
- `files_touched`: All files created or modified

### Wiki-Link Integration

Add [[wiki-links]] throughout the export for key terms:

**Technologies:** [[TypeScript]], [[Python]], [[React]], [[XState]], [[Postgres]]
**Tools:** [[Claude Code]], [[Cursor]], [[Obsidian]], [[Git]]
**Concepts:** [[state machine]], [[knowledge graph]], [[API]], [[authentication]]
**Projects:** [[Intuition]], [[Portal]], [[MCP]]

Apply wiki-links to:
- File descriptions (language/framework)
- Technical decisions
- Tools and technologies mentioned
- Project references

### Summary Export (-s)

```markdown
---
date: YYYY-MM-DD
source: claude-code
project: {detected}
umbrella: {if applicable}
session_type: engineering
tags: [typescript, react, xstate]
files_touched:
  - src/components/example.tsx
message_count: N
duration: ~2 hours
working_directory: /path/to/project
git_branch: feature/example
---

# Conversation Summary: [Topic]

## Overview
[2-3 paragraph detailed summary with [[wiki-links]] for key concepts]

## Key Objectives
- [Main goals achieved with [[wiki-links]] to technologies]
- [Problems solved with technical specifics]

## Technical Details
- **Language/Framework**: [[TypeScript]], [[React]]
- **Tools Used**: [[Claude Code]] Read, Edit, Bash, Glob
- **Git Status**: branch `feature/example`, 5 files changed

## Files Modified
- `src/components/example.tsx` - [description] ([[TypeScript]], [[React]])
- `src/hooks/useExample.ts` - [description] ([[TypeScript]])

## Key Decisions & Solutions
1. [Decision with rationale and [[wiki-links]]]
2. [Technical approach and alternatives considered]

## Next Steps
- [ ] [Follow-up action]
- [ ] [Another todo]
```

### Full Transcript Export (-f)

```markdown
---
date: YYYY-MM-DD
source: claude-code
project: {detected}
umbrella: {if applicable}
session_type: engineering
tags: [typescript, react, xstate]
files_touched:
  - src/components/example.tsx
message_count: N
tool_calls: M
duration: ~2 hours
working_directory: /path/to/project
git_branch: feature/example
---

# Full Conversation Transcript: [Topic]

## Session Metadata
- **Platform**: macOS
- **Working Directory**: [path]
- **Total Messages**: [count]
- **Tools Used**: [count by type]

## Conversation

### User [timestamp]
[Full user message]

### Assistant [timestamp]
[Full assistant response with [[wiki-links]] preserved]
[Tool usage details if applicable]

[Continue for entire conversation...]

## Files Created/Modified
- `path/to/file.ext` - [description] ([[Language]])

## Session Statistics
- Messages: N
- Tool calls: M
- Files created: X
- Files modified: Y
```

### Both Export (-b)

Create two separate files with consistent frontmatter:
- `YYYY-MM-DD-HHMM-topic-summary.md` - Summary format
- `YYYY-MM-DD-HHMM-topic-transcript.md` - Full transcript format

Both files get the same frontmatter for consistent knowledge graph ingestion.

## Full Transcript via JSONL Parser

For `-f` and `-b` exports, use the JSONL parser to generate the complete transcript from the raw conversation log. This captures the full conversation including pre-compaction content.

### How to generate the transcript file:

1. Find the current session's JSONL file:
   - The JSONL path is available in the conversation context (system prompt or transcript metadata)
   - Alternatively, find the most recent `.jsonl` in `~/.claude/projects/` matching the current working directory
2. Run the parser:
   ```bash
   python3 ~/.config/claude-code/hooks/lib/parse-transcript.py <jsonl_path> --export-markdown <output_path>
   ```
   - This produces clean markdown: no emojis, system noise stripped, tool calls shown with context
   - Supports `--since-timestamp ISO_TIMESTAMP` to export only a time range
3. Read the generated file and prepend the YAML frontmatter (from the frontmatter template above)
4. The parser handles: system-reminder stripping, tool call formatting, wiki-links, session stats

### Fallback (if JSONL not available):

If the JSONL file can't be found, fall back to the previous approach:
1. Read vault path from `~/.config/claude-code-workflow/config.json` (key: `obsidian_vault_path`)
2. Look for transcript at: `[vault_path]/ai-chats/transcripts/[YYYY-MM-DD]/daily-session-[YYYY-MM-DD].md`
3. Check for archived checkpoints at: `[vault_path]/ai-chats/transcripts/[YYYY-MM-DD]/archives/`
4. Reconstruct from checkpoint summaries + current context

### For summary exports (`-s`):
Use the JSONL parser's default mode (no `--export-markdown`) to get structured JSON with session stats, then combine with your own summary of the conversation content.

## Common Obsidian Locations

If user types 'obsidian', check these common vault locations:
- ~/Documents/Obsidian/
- ~/Documents/projects/web-projects/jonathanprozzi/seeds/
- ~/Obsidian/
- ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/

## Implementation Steps:
1. Parse command arguments to determine export type
2. Load configuration from config files
3. **Detect project** from git or directory structure
4. Check for existing daily transcript file
5. Handle vault path (prompt if needed)
6. Generate appropriate filename(s)
7. **Generate frontmatter** with all required fields
8. **Add wiki-links** to content for key terms
9. Create the export content
10. Write file(s) to specified location
11. **Update daily note** (unless `-n` flag)
12. Update config with last export timestamp
13. Confirm success with full path(s)

## Daily Note Integration (Default Behavior)

After creating the export file(s), update today's daily note in the Obsidian vault to maintain unified visibility across all Claude sessions.

### When This Runs
- **Default:** Always runs when `obsidian_vault_path` is configured
- **Skip with:** `-n` or `--no-update` flag

### Implementation

**Use the helper script** for reliable, consistent updates:

```bash
~/.config/claude-code/hooks/lib/add-export-to-daily.sh "<project>" "<topic>" "<export_path>" "<description>"
```

**Parameters:**
- `project`: Detected project name, title-cased (e.g., "Intuition Portal")
- `topic`: 2-4 word topic from conversation (e.g., "XState Refactor")
- `export_path`: Relative path from vault root (e.g., "ai-chats/claude-code/intuition-portal/2025-12-11-0930-xstate-refactor-summary.md")
- `description`: Brief summary of key accomplishments (under 80 chars)

**Example call:**
```bash
~/.config/claude-code/hooks/lib/add-export-to-daily.sh \
  "Intuition Portal" \
  "XState Refactor" \
  "ai-chats/claude-code/intuition-portal/2025-12-11-0930-xstate-refactor-summary.md" \
  "Transaction queue implementation, state machine fixes"
```

The script handles:
- Finding the vault path from config
- Locating today's daily note
- Finding or creating the Claude Sessions section
- Inserting the entry in the correct position
- Proper wiki-link formatting

### Entry Format (produced by script)

```markdown
- ~HH:MMam - [[ai-chats/claude-code/{project}/{filename}|{Project}: Topic]] - Brief description
```

**Format guidelines:**
- **Time:** Current time with `~` prefix (approximate)
- **Link:** Points to summary file (or transcript if summary-only)
- **Display text:** `{Project}: {Topic}` format
- **Description:** Brief summary of key accomplishments (under 80 chars)

### Examples

**From intuition-portal project:**
```markdown
- ~9:14am - [[ai-chats/claude-code/intuition-portal/2025-12-08-0914-ai-writes-modal-ux-fixes-summary|Intuition Portal: AI Writes UX Fixes]] - Rate limiting refactor, modal close buttons, AI SDK v5 migration
```

**From seeds vault (personal):**
```markdown
- ~2:30pm - [[ai-chats/claude-code/seeds/2025-12-08-1430-surrealdb-adapter-summary|Seeds: SurrealDB Adapter]] - Vector adapter implementation, query interface design
```

**From hats-protocol project:**
```markdown
- ~4:15pm - [[ai-chats/claude-code/hats-protocol/2025-12-08-1615-subgraph-fixes-summary|Hats Protocol: Subgraph Fixes]] - Event handler updates, entity relationship mapping
```

### Edge Cases (handled by script)

| Scenario | Behavior |
|----------|----------|
| `obsidian_vault_path` not configured | Exit with error message |
| Daily note doesn't exist | Exit with error message |
| Claude Sessions section doesn't exist | Create section before adding entry |
| Export from seeds vault itself | Still adds entry (consistent behavior) |

## Alignment with Knowledge System

This command produces exports compatible with:
- [[Unified Knowledge System Plan]] - folder structure and frontmatter schema
- [[Personal World Model PRD]] - knowledge graph ingestion
- Daily session workflow - same wiki-link conventions

Exports go to: `ai-chats/claude-code/{project}/YYYY-MM-DD-HHMM-topic.md`

## Error Handling:
- Create directories if they don't exist
- Handle permission errors gracefully
- Validate vault path exists
- Provide clear error messages

Format as professional markdown optimized for knowledge management systems and graph database ingestion.
