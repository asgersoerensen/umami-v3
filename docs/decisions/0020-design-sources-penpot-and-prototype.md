# 0020 — Penpot for how it looks, the HTML prototype for how it behaves

- **Status:** Accepted · 13 Nov 2026 (owner)
- **Context:** The UI draft (`design/ui-draft/index.html`, reviewed as a
  Paradev page, versions 1–5) runs the real list builder, and most review
  comments were about behaviour. Visual design (tokens, components, pixel
  layout) has no proper home, and a designer can't work in an HTML file.
  Penpot (open source, has an official MCP server) is now connected.

## Decision

Two design sources, each authoritative for one thing:

| Source | Owns | Reviewed by |
|---|---|---|
| **Penpot** (file "Umami") | Design tokens (colour, type, spacing, radii), the component library, static screen designs at 390 / 320 pt and standard / XL type, the assistant chat design | Comments in Penpot |
| **HTML prototype** `design/ui-draft/index.html` | Behaviour: flows, states, list-builder output, swipe actions, toasts, stale rules, copy in context | Paradev page comments |
| **`docs/product/spec.md`** | The rules both must follow; wins any conflict | — |

- **Tokens flow one way: Penpot → code.** Penpot's design tokens are exported
  (W3C design-tokens JSON) into the repo and generate `packages/ui` tokens; the
  prototype's CSS variables are then refreshed from the same file. Nobody edits
  token values in code or in the prototype by hand.
- **The prototype stays a behaviour tool.** It may lag Penpot visually; it
  isn't polished to pixel parity. When behaviour changes, the prototype changes
  first and is reviewed; Penpot follows only if the screen looks different.
- **The repo keeps the record.** `design/ui-draft/` (source) and
  `design/tokens/` (exported tokens) are versioned in git. Penpot files are
  linked from `design/README.md` with the file URL; a PNG export of each v1
  screen is committed at each release milestone, so the record doesn't depend
  on a Penpot account.
- **Paradev pages stay a review surface only.** The published page is
  regenerated from the repo file and never edited directly.

## Consequences

- E-DS tasks `j8j.2` (tokens) and `j8j.4` (components) are done in Penpot
  first, then implemented; `j8j.5` (servings control) is a Penpot design task.
- The assistant chat design (`s0c.2`) is designed in Penpot, with a scripted
  prototype screen for flow review.
- One more tool to keep in sync; the one-way token flow is what keeps that
  cheap.
