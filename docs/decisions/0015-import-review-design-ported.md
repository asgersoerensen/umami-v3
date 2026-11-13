# 0015 — Port v2's import review design into v3

- **Status:** Accepted · 12 Nov 2026
- **Gap resolved:** spec §7 says it is superseded by `docs/import-review-design.md`
  (UMA-11), which didn't exist in this repo. It exists in umami-v2.

## Decision

Port v2's `import-review-design.md` to **`docs/product/import-review-design.md`**,
adapted to v3:
- Danish copy throughout (spec §12 voice); new strings marked `[NY]`.
- Unknown ingredient → local ingredient (ADR 0003).
- Parse anonymously; ~~sign in at `Gem`~~ save without an account (ADR 0006, amended 13 Nov 2026).
- No method text; link-back row; image URL with `ImportTile` placeholder
  (ADR 0010).
- Line contract verbatim from v2 (ADR 0011).
- Two-stage skeleton (ADR 0013).
- Timings from v2: **soften at 12 s**, fail into paste-text (7d-2) at **25 s**.
  There is no hard 15 s timeout.
- Soft cap 7 at `Gem og tilføj` (ADR 0004).

## Spec impact (rev 4, §7)

The pointer becomes `docs/product/import-review-design.md`; §7's 15 s timeout
and progressive shimmer are marked superseded.
