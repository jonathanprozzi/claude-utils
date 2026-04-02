---
name: zork
description: "Play Zork I text adventure via dfrotz with persistent save state and optional Obsidian sync. Use when the user wants to play Zork, explore interactive fiction, or test text adventure parser conventions."
allowed-tools: Bash, Read, Edit
---

# Zork Interactive Fiction Skill

Play Zork I via dfrotz with persistent save state and optional Obsidian integration for capturing learnings. Builds experiential intuition about text adventure parser conventions.

## Workflow

1. **Play a turn** — run `bash scripts/play.sh "go north"` with any valid Zork command
2. **Check status** — run `bash scripts/status.sh` to see current room and inventory
3. **Start fresh** — run `bash scripts/new.sh` to archive current save and begin a new game
4. **Configure Obsidian sync** — run `bash scripts/setup.sh /path/to/vault` to sync transcript and learnings

## Commands

| Invocation | Script | Purpose |
|------------|--------|---------|
| `/zork look` | `scripts/play.sh "look"` | Describe current room |
| `/zork go north` | `scripts/play.sh "go north"` | Move in a direction |
| `/zork take lamp` | `scripts/play.sh "take lamp"` | Pick up an item |
| `/zork inventory` | `scripts/play.sh "inventory"` | List carried items |
| `/zork` | `scripts/status.sh` | Show current room and inventory |
| `/zork new` | `scripts/new.sh` | Archive save and start fresh |
| `/zork setup` | `scripts/setup.sh` | Configure Obsidian vault sync |

## Game State

- **Save file**: `state/claude.sav.qzl` — automatically saved after each turn
- **Transcript**: append-only log at `state/TRANSCRIPT.md` (or Obsidian vault if configured)
- **Config**: `state/config.json` — Obsidian vault path (optional)

## Troubleshooting

- If `play.sh` fails, verify dfrotz is installed: `which dfrotz` (install via `brew install frotz`)
- If save state seems corrupted, run `scripts/new.sh` to archive it and start fresh

## Parser Reference

- **Verbs**: `look`, `examine`, `take`, `drop`, `open`, `close`, `go`, `read`, `inventory`
- **Directions**: `north`, `south`, `east`, `west`, `up`, `down`, `ne`, `nw`, `se`, `sw`
- **Abbreviations**: `n` for north, `i` for inventory, `l` for look

See [README.md](README.md) for installation, Obsidian sync details, and dfrotz flags.
