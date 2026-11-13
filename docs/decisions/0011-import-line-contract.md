# 0011 — Import line contract (v2 format, verbatim)

- **Status:** Accepted · 12 Nov 2026
- **Amended 12 Nov 2026:** added `is_range` and `quantity_high` (import design §10, point 7).
- **Answers:** spec §11 Q1 (can the pipeline return per-line confidence?)
- **Source:** umami-v2 `docs/import-pipeline-contract.md` (ADR 0016)

## Context

The review screen hoists low-confidence lines into `Tjek disse`. Every line is
broken into its parts — quantity, unit, ingredient, preparation — and the
confidence score sits *on top of* that breakdown, saying how sure we are of
each part. The parser's quality is uncertain, so it is a **separate parallel
track behind this contract**; the screens and the list can be built against
fixtures before the parser is good.

## Decision — the line

| Field | Notes |
|---|---|
| `position` | int, unique, ascending — source order |
| `raw_text` | required, never blank, kept forever |
| `quantity` | decimal or null; Danish comma at the edges, decimal point inside. For a range, the **low** end |
| `quantity_high` | decimal or null — the high end of a range ("2–3 spsk" → 3); null otherwise |
| `is_range` | bool — true when the source gave a range; `quantity` holds the low end |
| `unit` | closed §9 set or null |
| `ingredient_id` | canonical id, or null when unresolved |
| `ingredient_match` | `exact` \| `alias` \| `fuzzy` \| `unresolved` |
| `suggested_ingredients` | ≤5 × `{id, name, display_plural, aisle}` — pre-fills the fix sheet |
| `preparation` | string or null (size words go here — 0018 V7) |
| `is_optional` | bool |
| `dropped_unit_word` | the unit word we saw but couldn't map, or null |
| `confidence_parts` | `{quantity, unit, ingredient, coverage}`, each 0–1 |
| `confidence` | `min(confidence_parts)` |

**Rules**
- The weakest part wins. Tie-break for which reason to show:
  ingredient > quantity > unit > coverage.
- On the LLM path the model may self-report a score; it may only **lower**
  confidence, never raise it.
- A line corrected by a person → `confidence = 1.0`, `confidence_parts = null`.
- The flag threshold (**0.8**) is **sent by the server** in the response; the
  app never hardcodes it.
- A range ("2–3 spsk") sets `quantity` = low end, `quantity_high` = high end,
  `is_range = true`, and **still flags** (quantity part 0.7). The review screen
  shows a range-specific reason ("Opskriften siger 2–3 — vi tog 2") instead of
  the generic guess reason. Scaling and the list use `quantity` only.
- A corrected line keeps `is_range` as the user left it; if the user edits the
  quantity, `is_range = false` and `quantity_high = null`.
- An unresolved ingredient always flags.

## Consequences

- Sub-score values (e.g. quantity 1.0 / 0.7 / 0.6 / 0.3) are **tunable
  internals of the parser epic**, not part of the contract.
- The parser epic opens with a **spike**: 30–50 recipes from the five named
  sites, measuring JSON-LD coverage, flag rate and wrong-match rate, which then
  becomes the golden set. It may start LLM-only.
