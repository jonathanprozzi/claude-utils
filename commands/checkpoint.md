---
disable-model-invocation: true
---

Create a timestamped checkpoint in the current daily session transcript.

## Command Usage
- `/checkpoint` - Create checkpoint with auto-generated summary
- `/checkpoint [note]` - Create checkpoint with specific note/context

## What This Command Does

1. **Identify the current transcript file:**
   - Look for `ai-chats/transcripts/YYYY-MM-DD/daily-session-YYYY-MM-DD.md` in the current vault
   - Use today's date

2. **Archive the current conversation:**
   - Create archive directory: `ai-chats/transcripts/YYYY-MM-DD/archives/`
   - Export full transcript to Markdown: `session-YYYY-MM-DD-HHMM-full.md`
   - This preserves the full conversation at checkpoint time

3. **Generate checkpoint entry:**
   - Current timestamp (e.g., `### ~3:45pm - Checkpoint`)
   - Link to the archived full transcript
   - If user provided a note, use that as the summary line
   - Otherwise, generate a brief summary of what's been accomplished
   - Include structured data matching PreCompact format

4. **Append to transcript:**
   - Add the checkpoint entry to the "Session Log" section (before "## Session Handoff")
   - Include key activities with [[wiki-links]]
   - Include summary points

5. **Update daily note:**
   - Find today's daily note at `journals/YYYY-MM-DD.md`
   - Increment the checkpoint count (e.g., `*(2 checkpoints)*` → `*(3 checkpoints)*`)
   - Add a nested bullet with deep link to the checkpoint section

## Checkpoint Entry Format (Transcript)

```markdown
### ~[TIME] - Checkpoint
[Summary line - user note or auto-generated]. [[ai-chats/transcripts/YYYY-MM-DD/archives/session-YYYY-MM-DD-HHMM-full|Full transcript]]

**Session:** [[Session Type]] | [N] messages | [N] tool calls | [N] created | [N] modified

**Key Activities:**
- Created: `path/to/file` ([[Language]])
- Modified: `path/to/file` ([[Language]])
- [Other notable activities with wiki-links]

**Summary:**
- Key accomplishment 1 with [[wiki-links]]
- Key accomplishment 2
- Decisions or insights

---
```

## Daily Note Entry Format

The nested bullet under the session entry should follow this format:

```markdown
- ~HH:MMam - [[transcript-link|Daily Session: Topic]] *(N checkpoints)* - Description
	- [[transcript#~TIME - Checkpoint|~TIME]]: Brief summary with key [[wiki-links]]
```

**Format guidelines for the summary:**
- Start with the main topic/accomplishment (not "Checkpoint:" prefix)
- Include 1-2 key wiki-links for graph connectivity
- Keep under 100 characters
- Be semantic (describe WHAT was done, not file paths)

**Good examples:**
- `Config fix complete, rich transcript template with [[YAML]] frontmatter`
- `Created [[Personal World Model PRD]], researched [[knowledge graph]] architecture`
- `[[Intuition]] transaction queue implementation, [[XState]] machine setup`

**Bad examples:**
- `.../transaction-executor/transaction-...` (truncated file path)
- `Pre-compaction (579 msgs)` (no semantic content)
- `Working on stuff` (too vague)

## Alignment with PreCompact Hook

This command produces output aligned with the PreCompact auto-checkpoint hook:

| Element | Manual `/checkpoint` | PreCompact Auto |
|---------|---------------------|-----------------|
| Transcript header | `### ~TIME - Checkpoint` | `### ~TIME - Checkpoint (Pre-Compaction)` |
| Archive link | Yes | Yes |
| Session stats | Yes | Yes |
| Key Activities | Yes | Yes |
| Summary section | `**Summary:**` bullets | `**User Requests:**` excerpts |
| Daily note format | Semantic summary | `Pre-compaction (N msgs). Type - topic` |

The header distinction (`Checkpoint` vs `Checkpoint (Pre-Compaction)`) makes it clear which are manual vs automatic.

## Wiki-Link Integration

Use [[wiki-links]] liberally for:
- Projects: [[Intuition]], [[Claude Code Daily Session]]
- Technologies: [[Python]], [[Bash]], [[TypeScript]], [[XState]]
- Concepts: [[knowledge graph]], [[world model]], [[dogfooding]]
- Tools: [[Obsidian]], [[Claude Code]], [[pgvector]]
- Your notes: [[PRD]], [[Intuition AI Research]]

## Implementation Notes

- Transcript file should already exist (created by `/daily-session`)
- Checkpoints are append-only - never modify previous entries
- Archive is created BEFORE the checkpoint entry (so link is valid)
- Deep link format: `[[path#Header Text|Display Text]]`
- Timestamps use `~` prefix to indicate approximate time
- Focus on semantic summaries, not file paths

## Example

User: `/checkpoint Finished knowledge graph PRD and research integration`

**Result in transcript:**
```markdown
### ~10:20am - Checkpoint
Finished knowledge graph PRD and research integration. [[ai-chats/transcripts/2025-12-02/archives/session-2025-12-02-1020-full|Full transcript]]

**Session:** [[Planning]] + [[Research]] | ~80 messages | ~40 tool calls | 2 created | 3 modified

**Key Activities:**
- Created: `Personal World Model PRD.md` ([[Markdown]])
- Read: [[ai-experiments-knowledge-graph-for-agents]] ([[ChatGPT]] export)
- Read: [[Intuition AI Research]], Intuition llms-full.txt

**Summary:**
- Created [[Personal World Model PRD]] with three-phase architecture
- Integrated [[ChatGPT]] research on [[knowledge graph]] / [[world model]]
- Validated cross-AI workflow: ChatGPT → Web Clipper → Obsidian → Claude Code
- Discussed [[Intuition]] bridge for future entity alignment

---
```

**Result in daily note:**
```markdown
- ~8:38am - [[daily-session-2025-12-02|Daily Session: Workflow & KG]] *(4 checkpoints)* - Testing workflow, knowledge graph planning
	- [[...#~8:49am - Checkpoint|~8:49am]]: Config fix, rich transcript template with [[YAML]] frontmatter
	- [[...#~10:20am - Checkpoint|~10:20am]]: Created [[Personal World Model PRD]], [[knowledge graph]] research integration
```
