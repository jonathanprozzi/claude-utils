---
disable-model-invocation: true
---

Generate the Daily GN report for the team's "Daily GN" ceremony.

## Usage

```
/daily-gn              # Generate for today
/daily-gn --date 2026-03-22   # Generate for a specific date
```

## What This Command Does

1. **Read the tracking log** (`local/daily-gn/.tracking/YYYY-MM-DD.jsonl`):
   - Parse each JSONL line for type, summary, and detail
   - Group by type for deduplication
   - If no tracking log exists, fall back to transcript/checkpoint analysis

2. **Read today's transcript and checkpoints** for additional context:
   - Check `local/ai-chats/transcripts/YYYY-MM-DD/daily-session-YYYY-MM-DD.md`
   - Scan checkpoint entries and session log
   - Extract accomplishments not already captured in the tracking log

3. **Scan today's exported sessions** (`local/ai-chats/claude-code/`):
   - Find summary files with today's date
   - Extract key accomplishments from Overview sections

4. **Compile the Daily GN** with three sections:
   - **Daily Accomplishments** — deduplicated, human-readable bullet list. Merge tracking log entries + transcript context. Consolidate related items (e.g., multiple file edits on the same project = one bullet). Order by significance, not chronology. Each bullet should be understandable to someone with no context on what you're working on.
   - **Troubleshooting** — any blockers, bugs, or issues encountered during the day. Extract from checkpoint notes, compaction summaries, or conversation context. If nothing notable: "None"
   - **Support Needed** — anything that requires help from the team. If nothing: "None"

5. **Write the Daily GN file** to `local/daily-gn/YYYY-MM-DD.md`

6. **Generate Slack-ready draft** and display it inline for copy-paste

7. **Display both** — show the Slack draft prominently (this is what you'll paste), and confirm the markdown file was saved

## Daily GN Markdown Template

```markdown
---
date: YYYY-MM-DD
day: DayOfWeek
week: NN
---

# Daily GN - YYYY-MM-DD

## Daily Accomplishments
- [Accomplishment 1 — written for team context, not personal shorthand]
- [Accomplishment 2]
- [Accomplishment 3]

## Troubleshooting
- [Issue or blocker, with brief context]
- None

## Support Needed
- [What you need + from whom if known]
- None

---
*Generated at HH:MMpm via /daily-gn*
```

## Slack Draft Format

Format as Slack-flavored text (bold with asterisks, bullets with •):

```
*Daily GN - Month DD*

*Accomplishments*
• Accomplishment 1
• Accomplishment 2
• Accomplishment 3

*Troubleshooting*
• None

*Support Needed*
• None
```

## Writing Guidelines

### Accomplishment Bullets
- **Team-readable**: Write for people who don't know what you've been doing. "Built HTML dashboard visualizing 86 HubSpot deals across 3 campaigns" not "Updated bd-skills-demo.html"
- **Outcome-focused**: What was achieved, not what tool was used
- **Specific**: Include numbers, names, and concrete outputs
- **Deduplicated**: Multiple tracking entries about the same work = one bullet
- **5-10 bullets typical**: Enough to show the day's work, not so many it's noise

### Troubleshooting
- Only include things that actually blocked or slowed you down
- Include what you tried and current status
- "None" is a perfectly good answer

### Support Needed
- Specific asks, not vague "could use help"
- Include who you think could help if you know
- "None" is a perfectly good answer

## Fallback (No Tracking Log)

If `local/daily-gn/.tracking/YYYY-MM-DD.jsonl` doesn't exist (tracking hook wasn't active, or first-time setup):

1. Read the daily session transcript for checkpoint entries and session log
2. Scan exported sessions
3. Review the conversation context directly
4. Ask the user: "I don't have a tracking log for today. Based on our session, here's what I captured — anything to add or change?"

This ensures the command works even before the tracking infrastructure is fully wired up.

## Notes

- This command can be run independently of `/end-day` — use it mid-day for a status check
- `/end-day` will offer to run this command if it hasn't been run yet today
- The markdown file in `local/daily-gn/` becomes the historical record
- The Slack draft is ephemeral — just for pasting
- All output stays in `local/` — never touches `github/`
- Week number in frontmatter uses ISO week numbering
