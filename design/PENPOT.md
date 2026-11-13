# Working in Penpot — brief for the UI design agent

Read first: `docs/decisions/0020-design-sources-penpot-and-prototype.md`, then
`docs/product/spec.md` (§0–§8, §10 visual rules, §12 copy deck). The spec wins
every conflict; raise disagreements as a bead, don't design around them.

## The file

Penpot file **"Umami"** (id `51f2d744-23b9-8138-8008-f08eee9dd64f`), reached
through the Penpot MCP server; the owner must have the file open with the MCP
plugin connected.

| Page | Contents |
|---|---|
| Tokens | One board, "Umami v1 · Tokens": swatches bound to tokens, type scale, spacing, radii. Regenerate it if tokens change; don't hand-edit values on it. |
| Components | Library components (bead `umami-v3-j8j.4`) |
| Screens 390 | v1 screens at 390 × 844, standard type (`umami-v3-j8j.9`) |
| Screens 320 XL | the same screens at 320 × 568 with XL type (font sizes × 1.24) |
| Assistant | stretch: chat sheet and proposal cards (`umami-v3-s0c.2`) |

## Rules

- **Use tokens, never raw values.** Token set `umami/core`: `color.*`
  (`ink.1–4`, `paper`, `surface`, `sunk`, `line.base|soft`,
  `accent|go|warn|stop .base|.wash`, `store.bg|on|ink`), `font.size.*`,
  `font.weight.*`, `space.*`, `radius.*`, `size.*`. Apply them with
  `applyToken`. A missing value means a new token, added to `umami/core` and
  noted on the bead. Penpot rejects a token name that is a prefix of another
  (hence `.base`).
- **Text styles:** the 12 library typographies (`umami/…`). Inter stands in for
  the platform font (SF Pro / Roboto).
- **Copy:** Danish, verbatim from spec §12. No lorem ipsum, no invented
  strings; a string the spec lacks goes on the bead as a proposal.
- **Content:** real recipes from the prototype (`design/ui-draft/index.html`,
  `DATA.recipes`). Hero images are placeholders until `umami-v3-450.4` lands;
  use the prototype's gradient + glyph tiles, never stock food photos.
- **Hard constraints (spec §10):** light only (in-store is a fixed dark
  screen style, not a theme); body ≥ 17 pt, in-store rows 22 pt; touch targets
  ≥ 44 pt; nothing may overflow the screen at 320 pt with XL type — check every
  screen with the export tool at both sizes.
- **Structure:** flex/grid layouts, semantic layer names, components with
  variants for states (e.g. ItemRow: to_buy / bought / skipped / swiped /
  edited / merged).
- **Behaviour is not your job.** Flows, states and list logic live in the HTML
  prototype; if a design needs a behaviour change, file a bead for the
  prototype first.

## Workflow

`bd ready --label role:ux` → claim → design → export PNGs of each finished
board to `design/screens/<page>/<board>.png` → close the bead with a short note
of what changed and any new tokens. Don't commit or push unless the owner asks.
Token export to code is `umami-v3-j8j.8` (not a design task).
