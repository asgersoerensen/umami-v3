# 0010 — Imports store facts, a link back and an image URL

- **Status:** Accepted · 12 Nov 2026 (a + a)
- **Conflict resolved:** spec §3 ("method text is shown but stored as a
  link-back + summary") vs the business plan's legal posture (don't republish
  source text or photos). Gap: §9 makes `hero_image` required for every recipe.

## Decision

**Method text.** Imported recipes store **no method text and no summary**. The
Recipe Sheet shows, in place of the method:

> Fremgangsmåde · **Se den på {domain} ↗**

Curated recipes keep `method_steps`.

**Images.** Store only the **source image URL** (from JSON-LD `image` or
`og:image`). The phone hotlinks it and caches it on the device. If it's
missing or fails to load, show an **authored placeholder illustration**
(design-system item, v2's `ImportTile`). We never copy, resize or re-host a
source image.

**Facts only.** Title, servings, total time, ingredient lines (which are facts),
source URL, source name.

**Parse cache.** The server caches parse results keyed by **normalised URL**
(facts + image URL only). A second import of the same URL — by anyone — skips
the LLM. Each user still gets their own recipe record.

**Pasted text.** The user's pasted text is kept as `raw_source_text` on *their
own* recipe for re-parse/debugging (from v2); never shown to anyone else.

## Spec impact (rev 4)

§3: replace the "shown but stored as link-back + summary" bullet; add the
link row. §9: `hero_image` required for curated, nullable for imports;
`method_steps` curated only. §12: `recipe.methodLink` [new].
