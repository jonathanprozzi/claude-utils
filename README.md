# Claude Utils

A collection of slash commands and utilities for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Currently focused on **[Obsidian](https://obsidian.md/) integration** for daily session continuity, with more tools planned.

This is a curated selection of my utilities. I dogfood and test each in my own workflows before sharing them in this repo. Many of these are co-created with Claude (recently Claude Opus 4.5) to solve specific problems we encounter in our daily collaboration.

The majority of the README currently focuses on my Obsidian workflow. As new utilities are added this will be updated with additional relevant context.

## Obsidian Utils For Session Continuity

Each session builds on shared insights from the last. Claude reads your daily notes and previous handoffs — your reflections become shared context, and collaboration compounds instead of resetting.

This is more than memory. By working inside a shared Obsidian vault, both human and AI have visibility into the same context — your reflections, decisions, and evolving ideas. The daily note becomes an anchor for collaboration, not just a log.

Much of my workflow was inspired by Ethan Mollick's article [Centaurs and Cyborgs on the Jagged Frontier](https://www.oneusefulthing.org/p/centaurs-and-cyborgs-on-the-jagged). My focus was on creating an integration where the human-AI boundary is fluid. Less task delegation, more thinking together. I started as a "centaur" — strategic delegation — but the daily session practice naturally evolved into something more integrated and more "cyborg" in structure. This seems to be the natural evolution of using Obsidian (and [Logseq](https://logseq.com/) before it) as my personal knowledge base.

## The Daily Workflow

This is an overview of how to use these commands and hooks within Obsidian. This is my opinionated process based on what has worked well for me, and I recommend customizing and personalizing to match your personal workflow.

```
Morning:
  1. Write reflections in your daily note (mood, focus, goals)
  2. cd to your Obsidian vault
  3. Run /daily-session
  → Claude reads your daily note + previous session's handoff
  → Creates a transcript file for the day

During the Day:
  4. Work together (thinking, building, researching)
  5. Run /checkpoint to capture progress
  → Checkpoints preserve context before compaction

End of Day:
  6. Run /end-day
  → Generates a "Session Handoff" for tomorrow
  → Updates your daily note with a summary
```

Each session builds on the last. The compounding returns are real.

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed
- An Obsidian vault (or any markdown-based notes system)
- Basic familiarity with slash commands

## Installation

### Option 1: Setup Script

```bash
git clone https://github.com/jonathanprozzi/claude-utils.git
cd claude-utils
chmod +x setup.sh
./setup.sh
```

The setup script will:

- Ask for your Obsidian vault path
- Create the required folder structure (won't delete existing content)
- Install commands to `~/.claude/commands/`
- Copy the daily journal template

> **Note:** The script will **overwrite** files with the same names (e.g., existing `/daily-session.md` command, existing `Daily Journal Template.md`). If you have customized versions, back them up first or use manual setup.

### Option 2: Manual Setup

If you prefer not to run the script or have an existing structure:

1. **Copy commands** to `~/.claude/commands/`:

   ```bash
   cp commands/*.md ~/.claude/commands/
   ```

2. **Create config** at `~/.config/claude-code-workflow/config.json`:

   ```json
   {
     "obsidian_vault_path": "/path/to/your/vault"
   }
   ```

3. **Ensure vault folders exist** (or adapt commands to your structure):
   - `journals/` — daily notes as `YYYY-MM-DD.md`
   - `ai-chats/transcripts/` — session transcripts
   - `ai-chats/claude-code/` — exported sessions

4. **Optionally copy** the daily journal template to your templates folder

## Commands

| Command | Description |
|---------|-------------|
| `/daily-session` | Start a daily thinking session with full context |
| `/checkpoint` | Capture progress mid-session |
| `/end-day` | Wrap up with a handoff for tomorrow |
| `/export-conversation` | Export any session (for non-daily work) |

### `/daily-session`

Starts a daily session by:

1. Reading today's daily note (your mood, focus, goals)
2. Finding the most recent session handoff
3. Creating a transcript file: `ai-chats/transcripts/YYYY-MM-DD/daily-session-YYYY-MM-DD.md`
4. Adding a link to your daily note's "Claude Sessions" section
5. Greeting you with context

### `/checkpoint`

Creates a timestamped checkpoint that:

- Summarizes what you've accomplished
- Lists key files touched
- Links to the daily note
- Preserves context before compaction

### `/end-day`

Wraps up the session by:

- Generating a "Session Handoff" with open threads
- Updating your daily note's "Day's End" section
- Creating continuity for tomorrow

### `/export-conversation`

For non-daily sessions (engineering work, research, etc.):

- Exports summary and/or full transcript
- Adds entry to your daily note
- Organizes by project

## Vault Structure

After setup, your vault will have:

```
your-vault/
├── journals/                    # Daily notes
│   └── YYYY-MM-DD.md
├── ai-chats/
│   ├── transcripts/             # Daily session transcripts
│   │   └── YYYY-MM-DD/
│   │       ├── daily-session-YYYY-MM-DD.md
│   │       └── archives/        # Checkpoint archives
│   └── claude-code/             # Exported sessions
│       └── project-name/
└── templates/
    └── Daily Journal Template.md
```

See [vault-structure.md](examples/vault-structure.md) for details.

## Configuration

Config is stored at `~/.config/claude-code-workflow/config.json`:

```json
{
  "obsidian_vault_path": "/path/to/your/vault"
}
```

The setup script creates this for you.

> **Note:** I sync my commands and hooks via a personal [dotfiles](https://dotfiles.github.io/) repo as my source of truth, then pull curated versions into claude-utils for public sharing. This isn't required — you can use claude-utils standalone.

## Philosophy

### Why Daily Sessions?

Claude Code sessions don't persist across restarts. Without structure, you start cold every day. This workflow solves that with:

1. **Handoffs** — End each day with context for tomorrow
2. **Checkpoints** — Capture progress before compaction
3. **Daily notes** — Human reflections inform AI context

### Cyborg Collaboration

This workflow is inspired by Ethan Mollick's ["Centaurs and Cyborgs on the Jagged Frontier"](https://www.oneusefulthing.org/p/centaurs-and-cyborgs-on-the-jagged):

- **Centaur:** Strategic delegation — human decides, AI executes
- **Cyborg:** Deep integration — human-AI boundary is fluid

This is cyborg-style. The daily note anchors both human reflection and AI context. Each session builds on shared understanding.

## Tips

1. **Run Claude Code from your vault directory** — Commands auto-detect paths
2. **Write morning reflections before /daily-session** — Give Claude context about your state
3. **Use /checkpoint liberally** — Especially before long tasks that might trigger compaction
4. **Let Claude update your daily note** — The "Claude Sessions" section tracks everything

## Scripts

The `scripts/` folder contains optional utilities:

### `parse-transcript.py`

Parses Claude Code JSONL transcripts and extracts structured data. Useful for:

- Checkpoint automation (extracting session stats, files touched)
- Exporting conversations to markdown
- Adding wiki-links to recognized terms

```bash
# Get session summary as JSON
python scripts/parse-transcript.py ~/.claude/projects/.../transcript.jsonl

# Export to markdown
python scripts/parse-transcript.py ~/.claude/projects/.../transcript.jsonl --export-markdown output.md

# Filter by timestamp
python scripts/parse-transcript.py transcript.jsonl --since-timestamp "2025-01-03T14:00:00Z"
```

The script includes a `WIKI_LINK_TERMS` dictionary you can customize for your own Obsidian graph.

## Hooks (Optional)

The `hooks/` folder contains automation scripts that integrate with Claude Code's hook system. These are **optional** — the slash commands work fine without them.

### `pre-compact-checkpoint.sh`

Automatically creates a checkpoint before Claude compacts the conversation context. This preserves your work even if you forget to run `/checkpoint` manually.

**What it does:**

- Parses the current transcript for stats and activities
- Archives the full conversation to `archives/`
- Inserts a checkpoint entry in your daily session transcript
- Updates the checkpoint count in your daily note

**To enable:**

1. Copy to your hooks directory:

   ```bash
   cp hooks/pre-compact-checkpoint.sh ~/.config/claude-code/hooks/
   cp hooks/lib/*.sh ~/.config/claude-code/hooks/lib/
   ```

2. Add to your Claude Code settings (`.claude/settings.json`):

   ```json
   {
     "hooks": {
       "PreCompact": [
         {
           "matcher": "",
           "hooks": ["~/.config/claude-code/hooks/pre-compact-checkpoint.sh"]
         }
       ]
     }
   }
   ```

**Note:** Hooks require a bit more setup and understanding of Claude Code's hook system. If you're new to this workflow, start with just the slash commands and add hooks later when you want automation.

## Skills

The `skills/` directory contains full Claude Code skills (vs. slash commands). These are cases where persistent state, bundled dependencies, or complex multi-turn behavior justified the extra structure.

### Zork

An adaptive Zork player that Claude can use to play classic text adventures, with persistent save state and optional Obsidian sync for capturing learnings.

This is the only "skill" (vs. command) that emerged from extensive testing with `/skill-builder` — an example of when the full skill format is actually warranted.

See [skills/zork/README.md](skills/zork/README.md) for installation, usage, and credits.

## Related

- **[claude-metaskills](https://github.com/jonathanprozzi/claude-metaskills)** — Methodology-focused commands for building skills and PRDs. Includes `/skill-builder` (which, ironically, almost always recommends commands over skills) and `/explore` for collaborative discovery.

## License

MIT

---

*Built by [@jonathanprozzi](https://github.com/jonathanprozzi)*
