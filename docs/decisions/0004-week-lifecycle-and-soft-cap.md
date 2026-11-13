# 0004 — One open-ended week, `Ryd ugen`, soft cap 7

- **Status:** Accepted · 12 Nov 2026
- **Gap resolved:** the spec has "one active week per user" but no rollover,
  no definition of `Ryd ugen`, and a soft cap of 6 with no stated rationale that
  is only enforced in the picker.

## Decision

- **No automatic rollover and no `week_start_date`.** The week is one open-ended
  set of meals until the user clears it.
  *v1.1 candidate:* a "Start en ny uge?" prompt after "Så er der købt ind".
- **`Ryd ugen`** (⚙ on Plan) clears: week entries, item states, the built list,
  hand-added items. It **keeps**: household servings, imported recipes, local
  ingredients. It asks for confirmation first.
- **Target stays 5. Soft cap = 7** (one per day — the natural ceiling for a
  family that shops once a week).
- The cap applies to **every add path**:
  - Picker ＋ → dims at 7, toast on tap;
  - Recipe Sheet `Tilføj til denne uge` → disabled at 7, toast on tap;
  - Plan `＋ Tilføj et måltid` → switches to the Opskrifter tab (rev 5; cap applies there);
  - Import review `Gem og tilføj til denne uge` → at 7, saves only (`Gem kun`)
    and shows the toast.
  - `Byt` (swap) is never blocked — it doesn't change the count.
- No hard lock, no modal.

## Copy (approved, in spec §12)

- `pick.maxToast`: **"Syv er hele ugen — fjern én først."** (replaces "Seks er
  rigeligt — fjern én først.")
- `week.clear.*` — see spec §12.

## Spec impact (rev 4)

§0 "4–6 meals" → "a target of 5, up to 7". §2 tray accepts 1–7; "Selection at 6"
→ "Selection at 7". §3, §4, §7 cap behaviour as above. §4 `Ryd ugen` defined.
§12 strings.
