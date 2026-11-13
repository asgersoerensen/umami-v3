# 0013 — No-reflow picker is a hard test; import skeleton is two-stage

- **Status:** Accepted · 12 Nov 2026
- **Answers:** spec §11 Q3 (cost of no-reflow in the picker and of the
  progressive import skeleton)

## Decision

**Picker no-reflow — load-bearing, a hard acceptance test.**
- Fixed card height; no reorder on select; stable list keys; selecting a card
  re-renders only that card and the tray.
- Acceptance: on a mid-range device, toggling ＋/✓ on any card leaves the scroll
  offset unchanged to the pixel and no other card moves. Automated where
  possible, manual on device otherwise.

**Import skeleton — two-stage, not per-field streaming.**
- **Stage 1 (~1 s):** title, image URL, domain (from JSON-LD / `og:` tags).
- **Stage 2:** ingredient lines.
- The app polls job status (`fetched` → `parsed`); the server writes stage 1 as
  soon as it has it. No streaming protocol.

## Consequences

Simple server (a status row), simple client (poll + two render states), and
the parsing screen still shows real content at ~1 s.
