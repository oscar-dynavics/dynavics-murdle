# Dynavics MURDLE Puzzle Authoring Prompt

Create one valid JSON object for a Dynavics MURDLE puzzle. Return JSON only, with no Markdown fences or explanation.

Requirements:
- Use the same number of unique suspects, weapons, and rooms, with at least 3 in each category. The puzzle grid size is derived automatically.
- Keep all names short enough to fit in a compact notebook grid.
- Include a title, subtitle, story title, short `storyHtml`, at least one clue, and a solution using entries from the three lists.
- `storyHtml` may use only `p`, `ul`, `li`, `strong`, `em`, and `span class="small"` elements. Do not use scripts, styles, links, images, or iframes.
- Make the clues internally consistent with the supplied solution. They are displayed to the player; the notebook is manually marked.
- Match this structure exactly:

```json
{
  "title": "MURDLE — Title",
  "subtitle": "3 suspects, 3 weapons, 3 locations",
  "storyTitle": "Story heading",
  "storyHtml": "<p>Short puzzle setup.</p>",
  "clues": [
    { "text": "A concise factual clue." }
  ],
  "suspects": ["Name one", "Name two", "Name three"],
  "weapons": ["Item one", "Item two", "Item three"],
  "rooms": ["Place one", "Place two", "Place three"],
  "solution": {
    "suspect": "Name one",
    "weapon": "Item one",
    "room": "Place one"
  }
}
```