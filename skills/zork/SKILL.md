---
name: zork
description: Play Zork text adventure via dfrotz. Use /zork <command> to play (e.g., /zork go north), /zork for status, /zork new to restart, /zork setup to configure Obsidian sync.
allowed-tools: Bash, Read, Edit
---

# Zork Interactive Fiction Skill

Play the classic text adventure Zork I via dfrotz, with persistent save state and optional Obsidian integration for capturing learnings.

## Quick Reference

| Command | What it does |
|---------|--------------|
| `/zork look` | Look around current room |
| `/zork go north` | Move north (or any direction) |
| `/zork take lamp` | Pick up an item |
| `/zork inventory` | Check what you're carrying |
| `/zork` | Show current status (look + inventory) |
| `/zork new` | Start a fresh game |
| `/zork setup` | Configure Obsidian vault for sync |

## How to Play

### Execute a single command:

```bash
bash scripts/play.sh "go north"
```

### Check current status:

```bash
bash scripts/status.sh
```

### Start a new game:

```bash
bash scripts/new.sh
```

### Configure Obsidian sync:

```bash
bash scripts/setup.sh /path/to/your/vault
```

## Game State

- **Save file**: `state/claude.sav.qzl` - automatically saved after each command
- **Transcript**: Append-only log of all commands and responses
- **Learnings**: Your observations about the game (update with /zork reflect)

## Obsidian Integration

If configured, transcript and learnings sync to your Obsidian vault as:
- `Claude Plays Zork Transcript.md`
- `Claude Plays Zork Learnings.md`

Run `bash scripts/setup.sh` to see current config or set a vault path.

## Tips

- Classic text adventure verbs: `look`, `examine`, `take`, `drop`, `open`, `close`, `go`, `inventory`
- Directions: `north`, `south`, `east`, `west`, `up`, `down`, `ne`, `nw`, `se`, `sw`
- You can abbreviate: `n` for north, `i` for inventory, `l` for look
- Save happens automatically after each command

## Purpose

This skill helps Claude build experiential intuition about text adventures and parser conventions, informing the design of AI companions in Emergent Quest.
