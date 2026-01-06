# Obsidian Vault Structure for Claude Code Workflow

This document describes the recommended vault structure for integrating Claude Code sessions with Obsidian.

## Directory Layout

```
your-vault/
├── journals/                    # Daily notes
│   ├── 2025-01-01.md
│   ├── 2025-01-02.md
│   └── ...
├── ai-chats/
│   ├── transcripts/             # Daily session transcripts
│   │   ├── 2025-01-01/
│   │   │   ├── daily-session-2025-01-01.md
│   │   │   └── archives/        # Checkpoint archives
│   │   │       └── checkpoint-2025-01-01-1430.md
│   │   └── 2025-01-02/
│   │       └── ...
│   └── claude-code/             # Exported sessions (non-daily)
│       ├── project-name/
│       │   ├── 2025-01-01-1430-topic-summary.md
│       │   └── 2025-01-01-1430-topic-transcript.md
│       └── another-project/
│           └── ...
├── templates/                   # Obsidian templates
│   └── Daily Journal Template.md
└── ...                          # Your other vault content
```

## Key Directories

### `journals/`
Daily notes using the daily journal template. This is where you write morning reflections and where Claude Sessions get linked.

**Naming convention:** `YYYY-MM-DD.md`

### `ai-chats/transcripts/`
Daily session transcripts created by `/daily-session`. Each day gets its own folder.

**Structure:**
- `daily-session-YYYY-MM-DD.md` — Main transcript file
- `archives/` — Checkpoint snapshots (pre-compaction captures)

### `ai-chats/claude-code/`
Exported sessions from `/export-conversation`. Organized by project.

**Naming convention:** `YYYY-MM-DD-HHMM-topic-summary.md` (or `-transcript.md`)

## The Daily Flow

```
Morning:
  1. Create/open today's daily note (journals/YYYY-MM-DD.md)
  2. Write morning reflections (Mood, Gratitude, Focus)

Session Start:
  3. cd to your vault directory
  4. Run /daily-session
  5. Claude reads your daily note + previous handoff

During the Day:
  6. Work together
  7. Checkpoints happen (manual /checkpoint or automatic pre-compaction)
  8. Each checkpoint links back to the daily note

End of Day:
  9. Run /end-day
  10. Claude generates Session Handoff + updates daily note
```

## Configuration

Set your vault path in `~/.config/claude-code-workflow/config.json`:

```json
{
  "obsidian_vault_path": "/path/to/your/vault"
}
```

Or use the setup script: `./setup.sh`

## Tips

1. **Run Claude Code from vault directory** — Commands can auto-detect paths
2. **Use consistent naming** — Date-based names enable cross-linking
3. **Let Claude update your daily note** — The Claude Sessions section tracks all sessions
4. **Archives are searchable** — Checkpoint archives preserve context lost to compaction
