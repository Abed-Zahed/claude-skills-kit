# report-comments

A drop-in comment widget for self-contained HTML (HyperText Markup Language) reports that Claude Code writes.

- Select text in the report, click **Comment**, and save a note. The text is highlighted.
- **Comments (n)**, bottom right, lists every note, takes general notes, and has **Copy all comments**.
- The copied text names the report, then for each note gives its section heading, the quoted text and the note. Paste it into the Claude Code session to answer everything at once.
- Notes are kept per file in the browser (localStorage), so closing the page loses nothing. Highlights are not restored after a reload; the notes are.
- No external dependencies. It uses the page's `--acc`, `--card`, `--fg`, `--bg`, `--line`, `--mut`, `--warn` and `--warnbg` CSS (Cascading Style Sheets) variables when present, its own colours otherwise. Light and dark mode are both covered, and it is hidden when printing.

## Use

Paste the whole content of `report_comments.html` just before `</body>`. Sections are found from the nearest `h1` to `h3` heading, inside `<main>` if the page has one.

Limit: a local page cannot send text into a Claude Code session, so the last step is copy and paste.

## Global rule

`CLAUDE_SECTION.md` is the line to add to `~/.claude/CLAUDE.md` on each machine.
