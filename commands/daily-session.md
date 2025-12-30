---
disable-model-invocation: true
---

Start a daily thinking/brainstorm session in the Obsidian vault.

## Usage

```
/daily-session          # Full mode (default) - creates transcript, updates daily note
/daily-session --light  # Light mode - context only, no file creation
```

## Modes

### Default (Full Mode)
Creates a transcript file, adds entry to daily note, full archival workflow. Use this for:
- Morning session starts
- Days with planned focused work
- When you want full documentation

### Light Mode (`--light`)
Reads context but skips file creation. Use this for:
- Late starts (afternoon/evening)
- Low-energy days
- Quick check-ins
- When you'll run `/end-day` shortly after

Light mode still:
- Reads today's daily note
- Finds and reads previous handoff
- Scans recent exports
- Greets with full context

Light mode skips:
- Creating transcript file
- Adding session entry to daily note

---

## What This Command Does (Full Mode)

1. **Read today's daily note** (`journals/YYYY-MM-DD.md`):
   - Extract mood from "Mood Check"
   - Extract focus items from "Today's Focus"
   - Note key reflections or context from their writing
   - Note any existing Claude Sessions entries

2. **Find and read the most recent handoff** (handles gaps gracefully):
   - Search for transcripts: `ai-chats/transcripts/*/daily-session-*.md`
   - Sort by date descending, exclude today
   - Read the most recent one's "Session Handoff" section
   - Note how many days ago the last session was (for context)
   - If no previous transcript exists: proceed without handoff context
   - If handoff section is incomplete: use what's available, note the gap

3. **Scan recent Claude Code exports** (cross-session context):
   - Search for summary files: `ai-chats/claude-code/**/*-summary.md`
   - **Exclude**: `ai-chats/claude-code/seeds/` (daily session exports are redundant with handoff)
   - Filter to files modified since the last daily session date
   - For each summary found:
     - Parse YAML frontmatter (project, tags, duration, files_touched)
     - Extract Overview section (1-2 sentence summary)
     - Extract Next Steps / Open items
   - Group summaries by project for the transcript
   - If no exports found: note this but proceed (not all work generates exports)

4. **Create today's transcript file**:
   - Create directory: `ai-chats/transcripts/YYYY-MM-DD/`
   - Create file: `daily-session-YYYY-MM-DD.md`
   - Use the template below, merging daily note + previous handoff + other session exports into rich context

5. **Add session entry to daily note**:
   - In the "Claude Sessions" section, add:
     ```markdown
     - ~HH:MMam - [[ai-chats/transcripts/YYYY-MM-DD/daily-session-YYYY-MM-DD|Daily Session: Topic]] *(0 checkpoints)* - Brief description
     ```
   - Include the approximate start time for continuity with checkpoint entries

6. **Greet with context**:
   - Summarize what you captured from their daily note and previous handoff
   - Highlight any notable work from other exported sessions
   - Mention open threads and priorities (including from other sessions)
   - Ask what they'd like to focus on first

## Transcript Template

```markdown
---
date: YYYY-MM-DD
type: daily-session
days_since_last: N
previous_session: "[[ai-chats/transcripts/PREV-DATE/daily-session-PREV-DATE]]"
projects: []
tags:
  - DailySession
  - ClaudeCode
---

# Daily Session Transcript - YYYY-MM-DD

## Today's Context

**From daily note reflections:**

| Field | Value |
|-------|-------|
| **Mood** | [extracted from Mood Check] |
| **Energy** | [inferred from their writing - e.g., "tired but motivated"] |
| **Focus** | [extracted from Today's Focus] |

**Key thoughts from morning reflections:**
- [Notable points from their Mood Check writing]
- [Ideas or context they mentioned]
- [Anything relevant to today's work]

---

## Previous Session Context

**Last session:** [[previous-session-link]] (N days ago)

### What We Accomplished
- [Items from previous handoff]

### Open Threads
1. [Priority items from previous handoff]
2. [Continuing work]

### Key Files from Last Session
- [Important files mentioned in handoff]

---

## Other Sessions Since Last Daily

*Exported Claude Code sessions since last daily session (from `ai-chats/claude-code/`, excluding `seeds/`):*

### [[Project Name]] (N sessions)

**[[...-summary|Session Title]]** (~duration)
- [1-2 sentence overview from summary]
- Open: [Next steps extracted from summary]

### [[Another Project]] (N sessions)

**[[...-summary|Session Title]]** (~duration)
- [Overview]
- Open: [Next steps]

*If no exports found: "No exported sessions since last daily session."*

---

## Session Goals

*Synthesized from daily note focus + open threads:*

- [ ] [Goal 1]
- [ ] [Goal 2]
- [ ] [Goal 3]

---

## Session Log

### ~[TIME] - Session Start

[Brief note about session initialization and context merge]

---

## Session Handoff

*To be generated at end of session via `/end-day` or manually*

---
```

## Template Field Guidelines

### Projects Array
Populate `projects` frontmatter by identifying:
- Explicit project mentions (e.g., "Intuition", "Claude Code Daily Session")
- Wiki-linked project references
- Work contexts mentioned in daily note

### Mood/Energy Extraction
Parse the Mood Check section for:
- Explicit mood statements ("I'm feeling...")
- Energy indicators ("tired", "energized", "motivated")
- Blockers or concerns mentioned

### Session Goals Synthesis
Combine:
- Today's Focus items from daily note
- Priority items from previous session's open threads
- Any explicit "I want to..." statements

## Notes

- This command merges human context (daily note) with collaboration context (previous handoff)
- The transcript becomes the rich, queryable record of the session
- Daily note stays clean with just links; transcript has full detail
- YAML frontmatter enables Dataview queries and future knowledge graph parsing
- Use `/checkpoint` throughout the session to capture progress
- Use `/end-day` to wrap up and generate handoff for tomorrow
- Use `date +"%I:%M%p"` for accurate timestamps (session start, log entries)
- The "Other Sessions" scan excludes `seeds/` since daily session handoffs are the authoritative source
- **Light mode** (`--light`) is ideal for late starts, low-energy days, or when you just need context without archival overhead
- Running `/end-day` after a light mode session is fine — it will note that no transcript exists for today
