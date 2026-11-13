# 0018 — Defaults for behaviour the spec leaves open

- **Status:** Accepted · 12 Nov 2026 (all V1–V19 accepted as proposed)
- **Amended 12 Nov 2026:** V9 auto-rebuild rule after an import is added (import design §10, point 1).
- **Amended 13 Nov 2026 (spec rev 5, UI-draft review):** V8 and V11 updated; V12 and V19 resolved; V20–V24 added.
- **Why:** gaps an agent would otherwise fill by guessing. Where v2 had a rule,
  it is used.

## Building the list

- **V1 — Item identity.** A list item's key = ingredient id (canonical or local)
  + unit family (weight / volume / its own unit). Item states and staple
  toggles carry over to a rebuilt list by key. **If a bought item's amount goes
  up on rebuild, it goes back to "to buy".** Hand-added items have their own
  UUID and always carry over.
- **V2 — Non-convertible units for one ingredient** → one row with joined
  amounts: `300 g + 2 stk gulerødder`. One tap checks it. The `Fra {n} retter` line shows the sources (rev 5; was ⓘ).
- **V3 — Display unit after merging** (v2 rule): the ingredient's
  `default_unit` if it's in the same family, else the largest unit that keeps
  the number ≥ 1. `4 dl` never shows as `400 ml`; `1500 ml` shows as `1,5 l`.
- **V4 — Rounding after scaling.** `dåse`, `pakke`, `bundt`, `fed`, `skive` →
  round **up** to a whole number. `stk` → up to the nearest ½. `dl`, `spsk`,
  `tsk` → nearest ½. `g` → nearest 5 below 100 g, nearest 25 from 100 g. Display
  ½ ¼ ¾ where exact, else a comma decimal.
- **V5 — Never scale** `knivspids` or lines with no quantity.
- **V6 — Plurals and `stk`.** Plural only if the ingredient has
  `pluralises = true` and the quantity is not null and not exactly 1. `stk` is
  never displayed on the list: `3 løg`, not `3 stk løg`.
- **V7 — Size words** (`store`, `små`, `mellemstore`…) move into
  `preparation` and are ignored when merging: `2 store løg` + `1 løg` → `3 løg`.
- **V8 — Three item states:** to buy ○ / bought ✓ / skipped ⊘. Staples and
  optional lines start **skipped**; one tap moves them to to-buy. *Rev 5:* a
  skipped row shows no checkbox, only `Skal købes` (V24). In-store mode
  shows only to-buy and bought items, and its `8 af 24` counts only those.
- **V9 — Stale triggers:** adding or removing a meal; changing household
  servings or a meal's servings override. *Not* stale: item-state changes,
  hand-added items.
  *Amendment:* when the user arrives on the List after `Gem og tilføj` on an
  import, the list is **rebuilt automatically** if no item is bought yet (or no
  list exists); if at least one item is bought, it is marked stale as usual.
  No other path auto-rebuilds.
- **V10 — Partial** means only "a meal in the week whose recipe data isn't on
  this phone yet". The list builds without it and shows the banner.
- **V11 — Hand-added items** (`Tilføj en vare`) that don't match an ingredient
  go in `ANDET` (matching ones: V20), survive rebuilds,
  and are cleared by `Ryd ugen`. `Fjern alle flueben` returns bought items to
  to-buy; it doesn't touch skipped staples.

## Picker and navigation

- **V12 — Launch screen:** ≥1 meal in the week → List; empty → Opskrifter tab (rev 5: the picker is a tab).
- **V13 — `Overrask mig`:** fills up to 5; disabled at ≥5. Candidates = recipes
  matching the active filters, not already in the week. Greedy pick: prefer a
  cuisine not yet in the week, then seasonal fit and `sort_weight` with a
  little randomness. If too few match, add what exists and show a toast
  (new copy, see spec rev 4 §12).
- **V14 — Seasons:** forår Mar–May, sommer Jun–Aug, efterår Sep–Nov, vinter
  Dec–Feb. `altid` always matches. In-season first, then `sort_weight`.
- **V15 — Chips:** `Vegetar` = tag `vegetarian` or `vegan`. `kr` = cost band
  `low`. `Børnevenlig` excludes `kid_friendly = null` (as the spec says).

## Scope trims

- **V16 — `Gem som note` is removed.** iOS has no public API to write to Notes;
  the share sheet already reaches Notes and Reminders. Handoff = share sheet
  (plain text, aisle-grouped) + `Kopiér`.
- **V17 — `Grupper efter opskrift` is cut from v1** (→ §10). Grouped behaviour
  of merged rows and checks is undefined, and it works against "merged lines are
  the product".
- **V18 — Toast durations:** undo toasts 5 s, all others 4 s.
- **V19 — Onboarding servings picker** (1–8 segmented at 320 pt with XL type)
  is flagged to the UX epic; it won't fit as drawn. No default chosen.
  *Resolved 13 Nov 2026 (rev 5):* a 4×2 grid, default 4.

## Rev 5 additions (13 Nov 2026, UI-draft review)

- **V20 — Hand-added items merge.** `Tilføj en vare` parses
  `[qty] [unit] name` (comma/point decimals, `½`, glued or abbreviated units:
  `500g`, `1,5kg`, `500 gr`, `2 stk.`; qty without unit = `stk`). If the name
  matches an ingredient (key, plural or alias, case-insensitive), the item is
  added to that ingredient's row as a source `Tilføjet af dig` with factor 1,
  summed within its unit family under V2–V4, and the row is set to to-buy.
  Otherwise it is a free-text `ANDET` row (V11). Golden fixtures cover the
  parser cases and the merge.
- **V21 — Adding never applies pending week changes.** The merge rebuilds
  against the week snapshot the list was built from, not the current week, so
  a stale list stays stale and V9 still holds.
- **V22 — Quantity override.** `Ret mængde` stores
  `{qty, unit, base_amount}` per row key, where `base_amount` is the
  recipe-derived amount when it was set. On every rebuild it replaces the first
  quantity part's display only if the row's recipe-derived amount still equals
  `base_amount`; otherwise it is deleted. Raising a bought row's amount returns
  it to to-buy.
- **V23 — Personal staples.** `Basisvare` (swipe) adds the ingredient to the household's
  `personal_staples`. A row starts skipped (and sits in `Basisvarer`) if
  `is_staple` **or** it is a personal staple **or** every source line is
  optional. `Skal købes` and `Spring over` change only this list's state:
  `Spring over` sets skipped without touching `personal_staples` (a
  non-staple stays in its aisle, greyed; a staple returns to `Basisvarer`). Personal staples
  survive `Ryd ugen`; they are removed only in `⚙ → Mine basisvarer`.
- **V24 — Skipped rows have no checkbox.** Their one action is `Skal købes`
  (row tap does the same), with an undo toast. A tick always means bought.
  Swipe actions (`Spring over`, `Basisvare`, `Ret mængde`, `Fjern` for own `ANDET` items) are
  also screen-reader custom actions.
