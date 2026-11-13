# 0003 — Consolidation is deterministic; unknown ingredients become local ingredients

- **Status:** Accepted · 12 Nov 2026
- **Conflict resolved:** business plan (LLM consolidation) vs spec §9 (canonical
  `ingredient_id` join); plus a gap: the spec has no answer for an imported
  ingredient that isn't in the canonical table.

## Decision

**Consolidation.**
- Lines merge only on **`ingredient_id` + unit family**. Units are the closed
  §9 set. Fixed conversions only: `dl↔ml↔l`, `g↔kg`. Nothing else converts;
  `2 fed` + `1 bundt` never merge.
- No LLM, no fuzzy matching, no network at list-build time (ADR 0002).
- The LLM's only role is at **import time**: proposing a canonical match for a
  line, which the user confirms in review (ADR 0011).

**Unknown ingredients.**
- If review ends with a line that has no canonical match, the user creates a
  **local ingredient**: normalised Danish name, aisle proposed by the LLM (or
  `andet`), `is_staple = false`.
- Local ingredients are **owned by an account** (imports always are — ADR 0006).
- A local ingredient merges with another line only on an **exact normalised
  name** match within the same account.
- Every local ingredient lands in a **curation queue** in Django admin, where an
  editor either **promotes** it to canonical or **maps** it to an existing
  canonical ingredient (adding an alias). Mapping rewrites the user's lines.
- The ingredient FK on an ingredient line is **never null**: it points at a
  canonical ingredient **or** a local one.

## Consequences

- The canonical table is the product's quality ceiling. Target ~300–400
  entries with Danish aliases and authored plurals before launch; this is
  content-epic work, seeded from v2 (ADR 0016).
- Normalisation (lower-case, trim, fold `æ/ø/å` → `ae/oe/aa`, strip size words —
  0018 V7) is one shared function used by import, local-ingredient matching and
  the curation queue.

## Spec impact (rev 4, §9)

`ingredient_id` → "canonical **or** local ingredient (never null)". Add a
*Local ingredient* table. Note that the list never calls the network or an LLM.
