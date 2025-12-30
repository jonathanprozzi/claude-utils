---
disable-model-invocation: true
---

Wrap up the daily session and generate handoff for tomorrow.

## Usage

```
/end-day              # Auto-detect session date from most recent incomplete transcript
/end-day --date 2025-12-16   # Explicitly specify the session date
```

## Date Detection (handles late-night sessions)

When running `/end-day` after midnight, the system date is technically "tomorrow" but you're conceptually wrapping up "yesterday." This command handles this automatically:

1. **If `--date YYYY-MM-DD` is provided**: Use that date explicitly
2. **Otherwise, auto-detect**:
   - Search for recent daily session transcripts: `ai-chats/transcripts/*/daily-session-*.md`
   - Find transcripts with an **incomplete handoff** (contains placeholder text: `*To be generated at end of session`)
   - Use the most recent incomplete transcript's date
   - If no incomplete transcript found, fall back to today's system date

This means running `/end-day` at 1am on 12/17 will correctly find and complete the 12/16 transcript if it's still open.

## What This Command Does

1. **Determine session date** (via auto-detection or `--date` flag)

2. **Read the session's transcript** (`ai-chats/transcripts/YYYY-MM-DD/daily-session-YYYY-MM-DD.md`):
   - Review the Session Log entries and checkpoints
   - Identify key accomplishments, decisions, and open threads

3. **Scan the session date's Claude Code exports** (cross-session aggregation):
   - Search for summary files: `ai-chats/claude-code/**/*-summary.md`
   - Filter to files with the session date in the filename (YYYY-MM-DD pattern)
   - For each summary found:
     - Parse YAML frontmatter (project, duration, files_touched)
     - Extract key accomplishments from Overview
     - Extract Next Steps / Open items
   - Group by project for the handoff

4. **Update the Session Handoff section** in the transcript:
   - Summarize what was accomplished (this session)
   - Include "Other Sessions Today" table with cross-session work
   - Create "Unified Open Threads" merging all session next steps
   - Note key files touched or created
   - Add context for tomorrow's session

5. **Update the session date's daily note** (`journals/YYYY-MM-DD.md`):
   - Finalize the Claude Sessions entry with accurate checkpoint count
   - Ensure description reflects what was actually done
   - Optionally add key learnings to "Learning Points" section

6. **Summarize and sign off**:
   - Provide a brief recap of the session
   - Mention what's ready for tomorrow

## Handoff Section Template

```markdown
## Session Handoff

*End of YYYY-MM-DD session*

### What We Accomplished (This Session)
- [x] [Completed item from daily session]
- [x] [Another completed item]

### Other Sessions Today

*From exported Claude Code sessions (`ai-chats/claude-code/`):*

| Project | Sessions | Key Accomplishments |
|---------|----------|---------------------|
| [[Project A]] | 2 | Brief highlights from summaries |
| [[Project B]] | 1 | Brief highlights |

*If no exports: "No other exported sessions today."*

### Unified Open Threads

**From Daily Session:**
1. [Priority item from this session]
2. [Another item]

**From Other Sessions:**
- [[Project A]]: [Next steps from that session's summary]
- [[Project B]]: [Next steps]

### Key Files
- [File paths that were created or modified - from all sessions]

### Session Stats

| Metric | Daily Session | All Sessions Today |
|--------|---------------|-------------------|
| Duration | ~X hours | ~Y hours total |
| Projects | N | M |
| Exports | - | N summaries |

### Context for Next Session
[1-2 sentences of unified context covering all work done today - this helps tomorrow's /daily-session greet effectively]
```

## Notes

- This pairs with `/daily-session` to complete the daily loop
- The handoff lives in the transcript (not a separate file) - single source of truth
- Tomorrow's `/daily-session` will read this handoff section AND scan for exports
- The "Other Sessions Today" aggregation ensures nothing falls through the cracks
- "Unified Open Threads" gives tomorrow a prioritized starting point across all work
- Keep the handoff concise but complete enough to resume context
- **No `/export-conversation` needed after this** — the handoff IS the export for the daily session
- Use `date +"%I:%M%p"` for accurate timestamps when writing handoff
- **Late-night sessions**: Auto-detection handles sessions that span past midnight. Use `--date` flag if you need explicit control.
