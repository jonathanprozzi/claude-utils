# Claude Utils

Curated slash commands and skills for Claude Code workflows.

## What's Included

### Commands

| Command | Description |
|---------|-------------|
| `/checkpoint` | Create a checkpoint in your session for easy resume |
| `/daily-session` | Start a daily working session with context |
| `/end-day` | End-of-day summary and handoff |

### Skills

*Coming soon*

### Hooks

*Coming soon* — Hooks for transcript capture, checkpoints, and session management.

Hooks require configuration (vault paths, etc.) and will include:
- Setup script for first-time config
- Documentation on each hook's purpose and triggers
- Graceful degradation when config is missing

## Installation

```bash
# Copy all commands
cp commands/*.md ~/.claude/commands/

# Or symlink for easy updates
for cmd in commands/*.md; do
  ln -s "$(pwd)/$cmd" ~/.claude/commands/$(basename "$cmd")
done
```

## Usage

Commands are invoked with `/command-name` in any Claude Code session.

## Structure

```
claude-utils/
├── commands/           # Slash commands (.md files)
│   ├── checkpoint.md
│   ├── daily-session.md
│   └── end-day.md
├── skills/             # Skills (folders with SKILL.md)
└── README.md
```

## Related

- [claude-metaskills](https://github.com/jonathanprozzi/claude-metaskills) — skills that help create other skills

## License

MIT

---

*Built by [@jonathanprozzi](https://github.com/jonathanprozzi)*
