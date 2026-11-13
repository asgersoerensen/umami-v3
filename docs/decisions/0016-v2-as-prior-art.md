# 0016 — umami-v2 is prior art; v3 is a fresh build

- **Status:** Accepted · 12 Nov 2026
- **Context:** `/Users/asger/projects/private/umami-v2` is a working codebase
  (Django API + Expo app, 439 tests, 13 commits) built against the same spec.
  Its README was sitting untracked in the v3 repo root.

## Decision

- v3 is a **fresh build**. v2 code is **not** ported wholesale.
- These are **reused after review** (each through the epic that owns it):
  - the **44 curated Danish recipes** (`slate.yaml`) with derived uuid5 ids
    (namespace `6f1e8a52-3c47-5a9b-9d21-0e7c4b8f1a30`, kept so ids stay stable);
  - the **canonical ingredient seed** and aliases;
  - **Danish tokens and parse rules** (`danish.py`: comma decimals, thousands
    separators, unit aliases, `nip`/`en smule` → `knivspids`, `[a-zæøå]+`
    tokenisation, unit words only count when quantified);
  - the **import eval set**;
  - **component-set design tokens**;
  - **data-model rules**: replay safety (absolute values, `checked_at` LWW,
    `Idempotency-Key`), deltas via `?updated_since=` with tombstones, Danish
    quantities at the edges / decimal inside, authored plurals with a
    `pluralises` flag, `normalise_name` folding æøå, the display-unit ladder,
    ranges take the low end and flag.
- Where v3 differs from v2, **the v3 decision stands**: list on device (0002 vs
  server-materialised), Procrastinate (0007 vs Celery), Render Frankfurt (0009
  vs Fly `iad`), `time_band` derived (0014 vs stored).
- The untracked v2 `README.md` is **replaced** with a v3 README.

## Known v2 gaps that carry over

- **No real hero photography.** v2's slate references 44 generated placeholder
  tiles (abstract gradient + glyph, owned by us), but the `.webp` files are not
  in the v2 repo, and placeholders are not acceptable for real users. The spec
  says a card without an image is unusable → placeholders are fine for internal
  builds, **real images block the family usability test and release.**
- Two lines in v2's `recipe_lines.yaml` lose part of their `prep` to an
  unquoted comma in a YAML flow mapping; the content import must quote or
  validate this.
- v2 never answered whether the import parser is good enough on markup-free
  pages (its live eval was 3 cases).
