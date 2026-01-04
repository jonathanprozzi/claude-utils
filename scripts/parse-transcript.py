#!/usr/bin/env python3
"""
Parse Claude Code JSONL transcript and extract structured session data.

Usage:
    python parse-transcript.py <transcript_path> [--since-timestamp ISO_TIMESTAMP]
    python parse-transcript.py <transcript_path> --export-markdown <output_path>

Output:
    JSON object with extracted structured data suitable for checkpoint summary
    OR markdown file with full conversation export
"""

import json
import re
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path
from typing import Optional


# Wiki-link mappings for Obsidian integration
WIKI_LINK_TERMS = {
    # Tools and technologies
    'python': '[[Python]]',
    'bash': '[[Bash]]',
    'typescript': '[[TypeScript]]',
    'javascript': '[[JavaScript]]',
    'rust': '[[Rust]]',
    'go': '[[Go]]',

    # Claude Code specific
    'claude code': '[[Claude Code]]',
    'claude': '[[Claude]]',
    'slash command': '[[slash commands]]',
    'slash commands': '[[slash commands]]',
    'hook': '[[Claude Code Hooks]]',
    'hooks': '[[Claude Code Hooks]]',
    'precompact': '[[PreCompact]]',
    'pre-compact': '[[PreCompact]]',
    'sessionstart': '[[SessionStart]]',
    'compaction': '[[compaction]]',
    'context window': '[[context window]]',

    # Obsidian specific
    'obsidian': '[[Obsidian]]',
    'vault': '[[Obsidian vault]]',
    'wiki-link': '[[wiki-links]]',
    'wikilink': '[[wiki-links]]',
    'daily note': '[[daily notes]]',
    'daily notes': '[[daily notes]]',

    # General development
    'dotfiles': '[[dotfiles]]',
    'git': '[[Git]]',
    'github': '[[GitHub]]',
    'api': '[[API]]',
    'json': '[[JSON]]',
    'jsonl': '[[JSONL]]',
    'markdown': '[[Markdown]]',

    # Concepts
    'prd': '[[PRD]]',
    'dogfooding': '[[dogfooding]]',
    'context management': '[[context management]]',
    'transcript': '[[transcript]]',
    'checkpoint': '[[checkpoint]]',
}


def add_wiki_links(text: str) -> str:
    """Add wiki-links to recognized terms in text."""
    result = text
    # Sort by length (longest first) to avoid partial replacements
    for term in sorted(WIKI_LINK_TERMS.keys(), key=len, reverse=True):
        # Case-insensitive search, but only replace whole words
        pattern = re.compile(r'\b' + re.escape(term) + r'\b', re.IGNORECASE)
        # Only replace if not already a wiki-link
        if f'[[' not in result or term.lower() not in result.lower():
            result = pattern.sub(WIKI_LINK_TERMS[term], result, count=1)
    return result


def parse_jsonl(file_path: str) -> list[dict]:
    """Read JSONL file and return list of parsed JSON objects."""
    messages = []
    with open(file_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    messages.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    return messages


def extract_tool_uses(messages: list[dict]) -> dict:
    """Extract tool usage statistics from messages."""
    tool_counts = Counter()
    files_read = set()
    files_written = set()
    files_edited = set()
    commands_run = []

    for msg in messages:
        if msg.get('type') != 'assistant':
            continue

        message_data = msg.get('message', {})
        content = message_data.get('content', [])

        if not isinstance(content, list):
            continue

        for item in content:
            if not isinstance(item, dict) or item.get('type') != 'tool_use':
                continue

            tool_name = item.get('name', '')
            tool_input = item.get('input', {})

            tool_counts[tool_name] += 1

            # Extract file paths from different tools
            if tool_name == 'Read':
                file_path = tool_input.get('file_path', '')
                if file_path:
                    files_read.add(file_path)

            elif tool_name == 'Write':
                file_path = tool_input.get('file_path', '')
                if file_path:
                    files_written.add(file_path)

            elif tool_name == 'Edit':
                file_path = tool_input.get('file_path', '')
                if file_path:
                    files_edited.add(file_path)

            elif tool_name == 'Bash':
                command = tool_input.get('command', '')
                description = tool_input.get('description', '')
                if description:
                    commands_run.append(description)
                elif command:
                    # Truncate long commands
                    commands_run.append(command[:60] + '...' if len(command) > 60 else command)

            elif tool_name == 'Glob':
                pattern = tool_input.get('pattern', '')
                if pattern:
                    files_read.add(f"glob:{pattern}")

            elif tool_name == 'Grep':
                pattern = tool_input.get('pattern', '')
                if pattern:
                    files_read.add(f"grep:{pattern[:30]}")

    return {
        'tool_counts': dict(tool_counts),
        'files_read': list(files_read)[:10],
        'files_written': list(files_written),
        'files_edited': list(files_edited),
        'commands_run': commands_run[:10]
    }


def extract_session_type(messages: list[dict], tool_data: dict) -> str:
    """Infer session type from patterns in the conversation."""
    tool_counts = tool_data.get('tool_counts', {})
    files_written = tool_data.get('files_written', [])
    files_edited = tool_data.get('files_edited', [])

    has_planning = tool_counts.get('TodoWrite', 0) > 0
    has_task_agent = tool_counts.get('Task', 0) > 0
    has_writes = len(files_written) > 0
    has_edits = len(files_edited) > 0
    has_reads = tool_counts.get('Read', 0) > 3
    has_grep = tool_counts.get('Grep', 0) > 0
    has_glob = tool_counts.get('Glob', 0) > 0

    if has_writes or has_edits:
        if has_planning:
            return "[[Planning]] + [[Implementation]]"
        return "[[Implementation]]"
    elif has_planning:
        return "[[Planning]]"
    elif has_reads or has_grep or has_glob:
        return "Research / Exploration"
    elif has_task_agent:
        return "Research (via agents)"
    else:
        return "Discussion"


def simplify_path(path: str) -> str:
    """Simplify file path for display."""
    home = str(Path.home())
    if path.startswith(home):
        path = "~" + path[len(home):]

    parts = path.split('/')
    if len(parts) > 4:
        return f".../{'/'.join(parts[-2:])}"
    return path


def get_file_type_link(filepath: str) -> str:
    """Get wiki-link for file type based on extension."""
    ext_map = {
        '.py': '[[Python]]',
        '.sh': '[[Bash]]',
        '.ts': '[[TypeScript]]',
        '.tsx': '[[TypeScript]]',
        '.js': '[[JavaScript]]',
        '.jsx': '[[JavaScript]]',
        '.rs': '[[Rust]]',
        '.go': '[[Go]]',
        '.md': '[[Markdown]]',
        '.json': '[[JSON]]',
        '.jsonl': '[[JSONL]]',
    }
    for ext, link in ext_map.items():
        if filepath.endswith(ext):
            return link
    return ''


def get_key_activities(tool_data: dict) -> list[str]:
    """Generate human-readable activity descriptions with wiki-links."""
    activities = []

    files_written = tool_data.get('files_written', [])
    files_edited = tool_data.get('files_edited', [])
    commands_run = tool_data.get('commands_run', [])
    tool_counts = tool_data.get('tool_counts', {})

    # Files created
    if files_written:
        for f in files_written[:5]:
            type_link = get_file_type_link(f)
            suffix = f" ({type_link})" if type_link else ""
            activities.append(f"Created: `{simplify_path(f)}`{suffix}")

    # Files modified
    if files_edited:
        for f in files_edited[:5]:
            type_link = get_file_type_link(f)
            suffix = f" ({type_link})" if type_link else ""
            activities.append(f"Modified: `{simplify_path(f)}`{suffix}")

    # Notable commands
    notable_commands = [c for c in commands_run if not c.startswith(('ls', 'cat', 'echo', 'head', 'tail'))]
    for cmd in notable_commands[:3]:
        activities.append(f"Ran: {cmd}")

    # If no file activities, note research activities
    if not activities:
        if tool_counts.get('Read', 0) > 0:
            activities.append(f"Read {tool_counts['Read']} files")
        if tool_counts.get('Grep', 0) > 0:
            activities.append(f"Searched codebase ({tool_counts['Grep']} searches)")
        if tool_counts.get('Task', 0) > 0:
            activities.append(f"Launched {tool_counts['Task']} research agents")
        if tool_counts.get('WebFetch', 0) > 0 or tool_counts.get('WebSearch', 0) > 0:
            activities.append("Researched web resources")

    return activities[:8]


def extract_user_messages_full(messages: list[dict]) -> list[dict]:
    """Extract full user messages with timestamps."""
    user_msgs = []

    for msg in messages:
        if msg.get('type') != 'user':
            continue

        message_data = msg.get('message', {})
        content = message_data.get('content', '')
        timestamp = msg.get('timestamp', '')

        if isinstance(content, str) and content.strip():
            user_msgs.append({
                'content': content.strip(),
                'timestamp': timestamp
            })

    return user_msgs


def extract_user_topics(messages: list[dict]) -> list[str]:
    """Extract key topics from user messages with wiki-links."""
    topics = []
    user_msgs = extract_user_messages_full(messages)

    for msg in user_msgs:
        content = msg['content']
        # Clean up - strip XML tags first
        clean = re.sub(r'<[^>]+>', '', content)  # Remove XML/HTML tags
        clean = clean.replace('\n', ' ').strip()

        # Skip very short messages
        if len(clean) < 20:
            continue

        # Get first two sentences or 150 chars, whichever is shorter
        sentences = re.split(r'(?<=[.!?])\s+', clean)
        if len(sentences) >= 2:
            excerpt = ' '.join(sentences[:2])
        else:
            excerpt = clean

        # Truncate if still too long
        if len(excerpt) > 150:
            excerpt = excerpt[:147] + '...'

        # Add wiki-links
        excerpt_with_links = add_wiki_links(excerpt)
        topics.append(excerpt_with_links)

    # Deduplicate based on first 50 chars
    seen = set()
    unique_topics = []
    for t in topics:
        t_key = t.lower()[:50]
        if t_key not in seen:
            seen.add(t_key)
            unique_topics.append(t)

    return unique_topics[:8]  # Return more topics


def summarize_conversation(messages: list[dict]) -> dict:
    """Create a comprehensive summary structure."""
    if not messages:
        return {
            'message_count': 0,
            'session_type': 'Empty',
            'activities': [],
            'user_topics': [],
            'tool_summary': {}
        }

    user_count = sum(1 for m in messages if m.get('type') == 'user')
    assistant_count = sum(1 for m in messages if m.get('type') == 'assistant')

    tool_data = extract_tool_uses(messages)
    session_type = extract_session_type(messages, tool_data)
    activities = get_key_activities(tool_data)
    user_topics = extract_user_topics(messages)

    timestamps = [m.get('timestamp') for m in messages if m.get('timestamp')]

    return {
        'message_count': len(messages),
        'user_messages': user_count,
        'assistant_messages': assistant_count,
        'session_type': session_type,
        'activities': activities,
        'user_topics': user_topics,
        'tool_summary': {
            'total_tool_calls': sum(tool_data['tool_counts'].values()),
            'tools_used': list(tool_data['tool_counts'].keys()),
            'files_created': len(tool_data['files_written']),
            'files_modified': len(tool_data['files_edited']),
        },
        'first_timestamp': timestamps[0] if timestamps else None,
        'last_timestamp': timestamps[-1] if timestamps else None
    }


def format_timestamp(iso_timestamp: str) -> str:
    """Convert ISO timestamp to readable format."""
    try:
        dt = datetime.fromisoformat(iso_timestamp.replace('Z', '+00:00'))
        return dt.strftime('%I:%M %p').lstrip('0').lower()
    except:
        return iso_timestamp


def extract_text_from_content(content) -> str:
    """Extract readable text from message content."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        texts = []
        for item in content:
            if isinstance(item, dict):
                if item.get('type') == 'text':
                    texts.append(item.get('text', ''))
                elif item.get('type') == 'tool_use':
                    tool_name = item.get('name', 'unknown')
                    texts.append(f"\n`[Tool: {tool_name}]`\n")
        return ''.join(texts)
    return str(content)


def export_to_markdown(messages: list[dict], output_path: str, session_info: dict = None):
    """Export full transcript to readable markdown."""
    lines = []

    # Header
    lines.append("# Full Session Transcript\n")

    if session_info:
        lines.append(f"**Exported:** {datetime.now().strftime('%Y-%m-%d %H:%M')}")
        lines.append(f"**Session Type:** {session_info.get('session_type', 'Unknown')}")
        lines.append(f"**Messages:** {session_info.get('message_count', 0)}")
        lines.append(f"**Tool Calls:** {session_info.get('tool_summary', {}).get('total_tool_calls', 0)}")
        lines.append("")

    lines.append("---\n")
    lines.append("## Conversation\n")

    for msg in messages:
        msg_type = msg.get('type')

        if msg_type == 'user':
            timestamp = msg.get('timestamp', '')
            time_str = format_timestamp(timestamp) if timestamp else ''
            message_data = msg.get('message', {})
            content = message_data.get('content', '')

            if isinstance(content, str) and content.strip():
                lines.append(f"### 👤 User ({time_str})\n")
                # Add wiki-links to user content
                content_with_links = add_wiki_links(content)
                lines.append(content_with_links)
                lines.append("\n")

        elif msg_type == 'assistant':
            timestamp = msg.get('timestamp', '')
            time_str = format_timestamp(timestamp) if timestamp else ''
            message_data = msg.get('message', {})
            content = message_data.get('content', [])

            text_content = extract_text_from_content(content)
            if text_content.strip():
                lines.append(f"### 🤖 Claude ({time_str})\n")
                # Add wiki-links to assistant content
                content_with_links = add_wiki_links(text_content)
                lines.append(content_with_links)
                lines.append("\n")

    lines.append("---\n")
    lines.append(f"*Transcript exported at {datetime.now().isoformat()}*\n")

    # Write to file
    with open(output_path, 'w') as f:
        f.write('\n'.join(lines))

    return output_path


def main():
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'No transcript path provided'}))
        sys.exit(1)

    transcript_path = sys.argv[1]
    transcript_path = str(Path(transcript_path).expanduser())

    if not Path(transcript_path).exists():
        print(json.dumps({'error': f'Transcript file not found: {transcript_path}'}))
        sys.exit(1)

    # Parse all arguments
    args = sys.argv[2:]
    export_markdown_path = None
    since_timestamp = None

    i = 0
    while i < len(args):
        if args[i] == '--export-markdown' and i + 1 < len(args):
            export_markdown_path = args[i + 1]
            i += 2
        elif args[i] == '--since-timestamp' and i + 1 < len(args):
            since_timestamp = args[i + 1]
            i += 2
        else:
            i += 1

    try:
        messages = parse_jsonl(transcript_path)

        # Filter by timestamp if specified
        if since_timestamp:
            messages = [m for m in messages if m.get('timestamp', '') >= since_timestamp]

        summary = summarize_conversation(messages)

        # Export to markdown if requested
        if export_markdown_path:
            export_to_markdown(messages, export_markdown_path, summary)
            print(json.dumps({'status': 'success', 'output': export_markdown_path, 'messages': len(messages)}))
        else:
            # Default: output summary JSON
            print(json.dumps(summary, indent=2))
    except Exception as e:
        print(json.dumps({'error': str(e)}))
        sys.exit(1)


if __name__ == '__main__':
    main()
