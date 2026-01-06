# Zork Skill for Claude Code

A Claude Code skill that lets Claude play Zork I via dfrotz with persistent save state and optional Obsidian integration for capturing learnings.

## Why This Exists

This skill demonstrates a use case where a full skill (not just a slash command) is appropriate:
- **Bundled dependencies**: Game file, scripts, state management
- **Persistent state**: Save file survives across sessions
- **External tool integration**: Wraps dfrotz CLI
- **Configurable output**: Optional sync to Obsidian vault

## Prerequisites

```bash
# Install frotz (Z-machine interpreter)
brew install frotz
```

The game file (`zork1.z3`) is included in the `data/` directory.

## Installation

If you cloned this from a dotfiles repo, run the install script:

```bash
./install.sh
```

This creates a symlink at `~/.claude/skills/zork/`.

For manual installation, copy or symlink the `zork/` directory to `~/.claude/skills/`.

## Usage

### Play a turn

```bash
~/.claude/skills/zork/scripts/play.sh "go north"
~/.claude/skills/zork/scripts/play.sh "take lamp"
~/.claude/skills/zork/scripts/play.sh "inventory"
```

### Check status (current room + inventory)

```bash
~/.claude/skills/zork/scripts/status.sh
```

### Start a new game

```bash
~/.claude/skills/zork/scripts/new.sh
```

Previous save is archived with a timestamp.

### Configure Obsidian sync (optional)

```bash
# Set vault path
~/.claude/skills/zork/scripts/setup.sh /path/to/your/vault

# Check current config
~/.claude/skills/zork/scripts/setup.sh

# Clear config (use local state/ only)
~/.claude/skills/zork/scripts/setup.sh clear
```

When configured, transcript and learnings sync to your Obsidian vault as:
- `Claude Plays Zork Transcript.md`
- `Claude Plays Zork Learnings.md`

## File Structure

```
zork/
├── SKILL.md              # Claude Code skill definition
├── README.md             # This file
├── scripts/
│   ├── play.sh           # Execute one command
│   ├── status.sh         # Show current room + inventory
│   ├── new.sh            # Start fresh game
│   └── setup.sh          # Configure Obsidian sync
├── data/
│   └── zork1.z3          # Zork I game file (Release 119)
└── state/                # Local state (gitignored)
    ├── claude.sav.qzl    # Current save file
    └── config.json       # User configuration
```

## How It Works

The skill wraps `dfrotz` (dumb frotz) to play Zork non-interactively:

```bash
echo -e "command\nsave\npath.qzl\ny\nquit\ny" | dfrotz -m -p -q -L save.qzl game.z3
```

Key flags:
- `-m` - No MORE prompts
- `-p` - Plain ASCII output
- `-q` - Quiet (no startup banner)
- `-L` - Load save file directly

Each turn: load save → execute command → save → quit. State persists via native Zork save files.

## Common Zork Commands

| Command | Description |
|---------|-------------|
| `look` / `l` | Describe current location |
| `inventory` / `i` | List carried items |
| `go <dir>` | Move (n, s, e, w, up, down, ne, nw, se, sw) |
| `take <item>` | Pick up item |
| `drop <item>` | Drop item |
| `open <thing>` | Open container/door |
| `examine <thing>` | Look at something closely |
| `read <thing>` | Read text |

## License

- Skill code: MIT
- Zork I game file: MIT (as of November 2025, via Microsoft/Activision)

## Credits

- Zork I by Infocom (1980)
- dfrotz by Stefan Jokisch, maintained by David Griffith
- Game file from [eblong.com](https://eblong.com/infocom/)
