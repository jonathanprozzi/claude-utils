---
disable-model-invocation: true
---

Generate a weekly review HTML presentation summarizing the full week's progress.

## Usage

```
/weekly-review              # Current week (Sunday through today)
/weekly-review --week 12    # Specific ISO week number
/weekly-review --range 2026-03-16 2026-03-21   # Custom date range
```

## What This Command Does

1. **Determine the week boundaries**
   - Default: Sunday of the current week through Friday (or today if before Friday)
   - `--week N`: Sunday-Friday of ISO week N in the current year
   - `--range START END`: Explicit date range

2. **Read all Daily GN files** for the week:
   - `local/daily-gn/YYYY-MM-DD.md` for each day in the range
   - Extract accomplishments, troubleshooting items, and support requests
   - Note which days have no GN (no session that day)

3. **Pull live data from external systems:**

   **HubSpot (BD Pipeline):**
   - Search deals in pipeline `877239690` (BD Partnerships)
   - Get total deal count and stage distribution
   - Identify deals created this week (by `createdate`)
   - Identify deals that changed stage this week (by `hs_lastmodifieddate` + stage comparison)
   - Count by campaign, owner, and tier
   - List active conversations (deals beyond Outreach Sent)

   **Linear (Task Progress):**
   - BizDev Partnerships team (`ffa98ff5`): completed issues this week
   - Growth team: completed issues this week
   - Any other relevant teams

   **Notion (Content & Docs):**
   - Search BOG Documentation database for pages created this week
   - Categorize: call prep docs, playbooks, strategy docs, co-marketing content
   - Search content calendar for items posted/drafted this week

4. **Generate the HTML presentation:**
   - Write to `local/weekly-review/YYYY-WNN.html`
   - Use the dark theme CSS from existing presentations (same variables, fonts, patterns)
   - Self-contained single file (inline CSS/JS, Google Fonts only external dep)

5. **Open in browser**

## HTML Sections

### 1. Hero
- "Week N Review" as title
- Date range subtitle (e.g., "March 17 - March 21, 2026")
- Headline stats row: total accomplishments, deals moved, content pieces created, days active

### 2. Daily Timeline
- One card per day (Sunday through Friday)
- Each card shows that day's accomplishments as bullet points
- Days without a GN file show "No session" in muted text
- Visual weight: more accomplishments = more prominent card
- Cards use subtle color coding by day

### 3. BD Pipeline Progress
- **Pipeline funnel** — bar chart showing deal count per stage (same style as bd-skills-demo.html)
- **Week's movement** — deals that advanced stage, new deals added
- **By campaign** — breakdown with counts
- **Active conversations** — list of deals beyond Outreach with current stage badges
- **By owner** — who's working what

### 4. Content & Narrative
- **Notion docs created** — grouped by type (call prep, playbook, strategy, co-marketing)
- **Content calendar** — items posted or drafted this week
- Count by category

### 5. Blockers & Support
- Aggregated from all daily GNs
- If all "None" across the week: show a clean "No blockers this week" card with a green accent
- Otherwise: list each blocker with the date it was raised and current status

### 6. Highlights
- Top 3-5 most significant accomplishments from the entire week
- Auto-selected by looking at: items that appear across multiple days, items involving external systems (Notion, HubSpot, Linear), items with specific numbers/metrics
- Presented as larger highlight cards with brief context

### 7. Future Extension Sections (hidden by default)
Include these sections in the HTML with `style="display:none"` so they can be enabled later:
- **Twitter Analytics** — placeholder for engagement, followers, top posts
- **Discord Analytics** — placeholder for member growth, activity
- **Portal Analytics** — placeholder for mk-experimental-apps data
- **Growth Metrics** — placeholder for custom KPIs

## CSS Theme

Reuse these CSS variables (same as bd-skills-demo.html and morpho-eng-briefing.html):

```css
:root {
  --bg: #0a0a0f;
  --surface: #12121a;
  --surface-2: #1a1a26;
  --surface-3: #22222f;
  --border: #2a2a3a;
  --text: #e4e4ec;
  --text-muted: #8888a0;
  --accent: #7c6aef;
  --accent-glow: rgba(124, 106, 239, 0.15);
  --green: #34d399;
  --blue: #60a5fa;
  --orange: #fb923c;
  --pink: #f472b6;
  --yellow: #fbbf24;
  --red: #f87171;
  --cyan: #22d3ee;
}
```

Use Inter font (Google Fonts). Same card styles, border-radius, hover effects. Consistent with the visual language already established.

## Data Pull Details

### HubSpot Queries
```
# All deals in BD pipeline
search_crm_objects: objectType=deals, pipeline=877239690
properties: dealname, dealstage, pipeline, hubspot_owner_id, priority_tier, partnership_type, outreach_channel, createdate, hs_lastmodifieddate

# Owner mapping
Matt = 584038042, Woods = 89091765, Fvnga = 89232348
```

### Linear Queries
```
# BizDev completed this week
list_issues: team=ffa98ff5, state=Done, updatedAt=-P7D

# Growth completed this week
list_issues: team=cf43712d-2b50-49a5-82a3-6392d456aea7, state=Done, updatedAt=-P7D
```

### Notion Queries
```
# BOG Documentation pages created this week
notion-search: query relevant to the week's work
Filter by timestamp within the week range
```

## Notes

- All output stays in `local/weekly-review/` — never touches `github/`
- The HTML is self-contained and works offline (except Google Fonts)
- Each week's file is preserved as a historical record
- Re-running for the same week overwrites the previous file
- The daily GN files are the source of truth for accomplishments — external system pulls add the quantitative layer
- Future analytics extensions just need: a data pull function + an HTML section template
