# Umami v1 — Product Spec & Core Flow

Feeds: `docs/decisions/` (ADRs), `docs/architecture/overview.md`,
`docs/product/import-review-design.md`

**Rev 5 — 13 Nov 2026.** Folds in the owner's review of the clickable UI draft
(drafts 1–4, `design/ui-draft/index.html`). Three tabs: the picker becomes the
`Opskrifter` tab (§0, §2, §4). Import never asks for sign-in; saved imports live
on the phone until first sign-in (§1, §7, §8; ADR 0006 amended). The List gets
`Skal købes` on skipped rows, a `＋` in the header, an add-item parser that merges
into ingredient rows, swipe actions (`Spring over`, `Basisvare`, `Ret mængde`, `Fjern`), personal
staples and a `Fra {n} retter` line in place of the ⓘ badge (§5, §9; ADR 0018
V20–V24). The recipe method is shown expanded (§3). Decided as drawn: the 4×2
servings grid and a `Næste` button in onboarding (§1), the dark in-store screen
style (§6), saving an import with flags still open (§7), and a compact tray
that never overflows at 320 pt with XL type (§2).

**Rev 4 — 12 Nov 2026.** Folds in the kickoff decisions (ADRs 0001–0018 in
`docs/decisions/`): the list is built on the phone (§5); one open-ended week
with a soft cap of 7 (§0, §2, §4); email + one-time-code sign-in, and a
parse-first import that requires sign-in at `Gem` (§7, §8); imports store no
method text and no image copy (§3, §9); `time_band` is derived, with bands
≤20 / 21–30 / 31+ (§9); defaults for list identity, rounding, staples and
`Overrask mig` (§2, §5, §6). Answers all four §11 questions. iOS ships first;
Android follows. Ticket and person references that were routing instructions
are removed; those that are historical record (§11 Answered) are kept.

**Rev 3 — 8 Sep 2026.** Records the board's UMA-15 decision: Denmark is the sole
v1 market and third-party grocery integration is declined outright (§8, §10,
§11.7). No screen or state changed — `da-DK` was already settled in rev 2 — but
the "is the UI Danish or English?" question now has an explicit answer in §12
rather than a default.

**Rev 2 — 8 Sep 2026.** Dan answered the two open decisions: the demo is for a
**Danish family**, and **day-of-week assignment stays cut**. This revision is
`da-DK` throughout — metric with `dl`, `kr` cost bands, Danish discount-store
walking order, a Danish cuisine set, Danish parser tokens and a Danish comma
decimal. All shipped strings are now shown in the wireframes as they ship;
§12 is the full copy deck with English glosses for the team. Rev 1 was `en-GB`.

**The bar:** a parent opens the app cold and has a finished grocery list in under
three minutes, one-handed.

---

## 0. The shape of the app

Three tabs. One takeover. Seven screens total (rev 5: the picker is a tab).

```
┌─ Onboarding (first run only, 3 cards) ────────────────┐
└───────────────────────┬───────────────────────────────┘
                        ▼
   ┌── TAB 1: PLAN ──┐  ┌── TAB 2: LISTE ──┐  ┌── TAB 3: OPSKRIFTER ──┐
   │  the week       │  │  consolidated    │◀─│  picker: cards +      │
   │  (0–7 meals)    │  │  groceries       │  │  filters + tray       │
   └──┬──────────────┘  └───────┬──────────┘  └──┬────────────────────┘
      │ ⇄ Byt                   ▼                │
      │  ┌─ PICKER (modal, swap only) ─┐  ┌─ IN-STORE (takeover) ─┐
      └──│  same cards, like-for-like  │  │  big rows, check off  │
         └─────────────────────────────┘  └───────────────────────┘

   ┌─ RECIPE SHEET (½ modal, from any card or Plan row) ─┐
   └─────────────────────────────────────────────────────┘
   ┌─ IMPORT (modal from Opskrifter: URL → parsing → REVIEW) ─┐
   └──────────────────────────────────────────────────────────┘
```

### Three decisions that buy the three minutes

**1. No day assignment.** A week is an unordered *set* of meals — target 5,
soft cap 7 — not a Mon–Sun grid. Dragging meals onto days costs ~60–90 seconds and changes the
grocery list by exactly nothing. → *Tradeoff: the plan looks less like a
calendar; families who want Tuesday-is-taco-night don't get it in v1.*
**Confirmed by Dan, 8 Sep — keep it cut.** Optional day *labels* were offered
and declined; they stay out of v1 and out of the data model (no `day` field).

**2. The tray, not a second screen.** The `Opskrifter` tab carries a persistent
bottom tray (`3 af 5 · Byg sedlen`) above the tab bar. You can go from cold open
to list without ever looking at the Plan tab. *Rev 5:* the picker is its own tab
rather than a modal over Plan, so recipes (curated and imported) have one home. Plan exists for the *second* session — reviewing, swapping,
adjusting servings. → *Tradeoff: two surfaces show the same week, so state has
to be shared, not duplicated.*

**3. Servings are set once, household-wide.** Asked in onboarding, applied to
every recipe. Per-recipe override lives on the Plan row for the odd meal.
→ *Tradeoff: no per-meal guest handling in the picker.*

### Navigation rules

- Launching with an empty week lands on **Opskrifter**, not Plan. First run = zero
  taps before the actual job.
- Launching with **at least one meal** in the week lands on **List**. That's the
  screen people live in.
- Tab order is **Plan · Liste · Opskrifter** (`tab.plan`, `tab.list`,
  `tab.recipes`). Onboarding, the empty states' `Vælg måltider` and Plan's
  `＋ Tilføj et måltid` all switch to Opskrifter. Only `⇄ Byt` opens the picker
  as a modal.
- `Byg sedlen` never blocks: it navigates immediately and the List screen renders
  its own loading state.
- There is **one open-ended week**. It doesn't roll over and has no start date;
  `Ryd ugen` (§4) starts again (ADR 0004).

---

## 1. Onboarding

First run only. Three cards, swipeable, `Skip` top-right on all three. Cards 1–2
also carry a `Næste` button (`common.next`) — decided in rev 5; swipe alone is
not discoverable enough. Card 3
carries the only question we ask.

```
┌──────────────────────────────┐   ┌──────────────────────────────┐
│                Spring over   │   │                Spring over   │
│        [illustration]        │   │        [illustration]        │
│                              │   │                              │
│   Aftensmaden er klaret.     │   │   Alle opskrifter.           │
│                              │   │   Alle sider.                │
│   Vælg fem måltider. Vi      │   │                              │
│   samler dem til én          │   │   Indsæt et link, og vi      │
│   indkøbsseddel.             │   │   trækker ingredienserne ud. │
│         ● ○ ○                │   │         ○ ● ○                │
└──────────────────────────────┘   └──────────────────────────────┘

┌──────────────────────────────┐
│                              │
│   Hvor mange laver I         │
│   mad til?                   │
│                              │
│     ┌───┐┌───┐┌───┐┌───┐     │   Rev 5: 4×2 grid, 1–8, default 4
│     │ 1 ││ 2 ││ 3 ││ 4 │     │   (fits at 320 pt with XL type).
│     ├───┤├───┤├───┤├───┤     │   Tapping one finishes onboarding
│     │ 5 ││ 6 ││ 7 ││ 8 │     │   and lands on Opskrifter.
│     └───┘└───┘└───┘└───┘     │
│                              │
│   Du kan ændre det senere.   │
│                              │
│         ○ ○ ●                │
└──────────────────────────────┘
```

**Copy, verbatim:**

| Slot | Copy (ships, `da-DK`) | English gloss |
|---|---|---|
| Card 1 title | **Aftensmaden er klaret.** | Dinner, decided. |
| Card 1 body | Vælg fem måltider. Vi samler dem til én indkøbsseddel. | Pick five meals. We'll turn them into one shopping list. |
| Card 2 title | **Alle opskrifter. Alle sider.** | Any recipe. Any site. |
| Card 2 body | Indsæt et link, og vi trækker ingredienserne ud — så den mad, I allerede laver, passer lige ind. | Paste a link and we'll pull out the ingredients, so the food you already cook fits right in. |
| Card 3 title | **Hvor mange laver I mad til?** | How many are you cooking for? |
| Card 3 footnote | Du kan ændre det senere. | You can change this later. |
| Skip | Spring over | Skip |

*Copy note: `I` (plural you) not `du` on card 1–3 titles — this is a household
app, and the plural is what makes it read as "your family" rather than "you, the
user". `du` returns for anything that is one person's action ("Du kan ændre det
senere").*

No account creation in onboarding. Sign-in is never required: it is offered
once after the first finished shop and is always available under `⚙` (see §8).

---

## 2. Opskrifter (Meal Picker)

Tab 3 and the primary screen when the week is empty. *Rev 5:* this was a
full-screen modal over Plan; it is now a tab with no ✕. The same picker opens
as a full-screen modal only for `⇄ Byt` (§4), titled `Byt {title}…`, without the
tray.

```
┌──────────────────────────────────────┐
│  Opskrifter             🔗 Importér  │  ← link icon opens Import
│  44 retter                           │  (· kun dine importerede when
├──────────────────────────────────────┤     that filter is on)
├──────────────────────────────────────┤
│ ⟨ Under 30 min │ Børnevenlig │ kr │ ⟩│  ← FilterChipRow, h-scroll
├──────────────────────────────────────┤     + ⚙ More opens filter sheet
│  ┌────────────────────────────────┐  │
│  │ [       hero image       ]     │  │
│  │                                │  │  RecipeCard
│  │  Kylling i karry            ＋ │  │  · 16:9 image
│  │  25 min · Nem · kr · 🧒        │  │  · title, 1 line, truncates
│  └────────────────────────────────┘  │  · MetaRow: time·difficulty·cost·kid
│  ┌────────────────────────────────┐  │  · ＋ / ✓ toggle, 48pt hit target
│  │ [       hero image       ]     │  │
│  │  Pølse-orzo i én gryde      ✓ │  │  Selected: card gets 2px accent
│  │  30 min · Nem · kr · 🧒        │  │  border, ＋ becomes ✓.
│  └────────────────────────────────┘  │
│              ⋮ (scroll)              │
├──────────────────────────────────────┤
│  ●●●○○  3 af 5     ⚡  Byg sedlen ▸ │  ← WeekTray, pinned above tab bar
├──────────────────────────────────────┤     ⚡ = Overrask mig (fills remainder)
│   Plan      Liste      Opskrifter    │  ← tab bar
└──────────────────────────────────────┘
```

**Interaction rules**

- Tap ＋ adds; tap ✓ removes. Card stays in place — **no reflow, no animation
  that moves the list**. Losing your scroll position mid-pick is the single
  worst thing this screen can do.
- Tap anywhere else on the card → Recipe Sheet (§3).
- Tray dots fill left to right. Target is 5; the tray accepts **1–7**. Dots
  beyond 5 render as extra filled dots.
- `Byg sedlen` is enabled from **1** meal, not 4. Never hold the user hostage to
  a target. Label stays `Byg sedlen` at any count.
- `⚡ Overrask mig` fills to 5 with recipes matching the currently active filters,
  weighted to vary cuisine. One tap = a full week. This is the sub-30-second path
  and it should be visible, not hidden in a menu. Rules (ADR 0018 V13): it fills
  up to 5 and is disabled at ≥5. Candidates are recipes matching the active
  filters that aren't already in the week. It picks greedily, preferring a
  cuisine not yet in the week, then seasonal fit (V14) and `sort_weight` with a
  little randomness. If too few recipes match, it adds what exists and shows the
  toast `pick.surpriseShort`.
- Filter chips are multi-select and AND-combined across categories,
  OR-combined within one (two cuisines = either).
- **No-reflow is a hard acceptance test** (ADR 0013): toggling ＋/✓ leaves the
  scroll offset unchanged and moves no other card. Fixed card height, no
  reorder on select, stable keys.

**Filters** — four chips visible, everything else behind `⚙ Mere`:

Visible: `Under 30 min` · `Børnevenlig` · `kr` · `Vegetar`
(`Under 30 min` = `total_time_min ≤ 30`; `Børnevenlig` excludes recipes where
`kid_friendly` is unknown; `kr` = cost band `low`; `Vegetar` = tagged
`vegetarian` or `vegan`.)
Sheet: time band, difficulty, cost band, cuisine (multi), dietary tags, season,
`Only my imports`.

**Tray sizing (rev 5, decided).** The tray must never extend past the screen.
`Byg sedlen ▸` is a compact pill (44pt high, 16pt side padding), its type
scales with Dynamic Type but caps at 17pt, and it may shrink (ellipsis as a
last resort, never clipping off-screen). **Below 340pt of width the dots are
hidden** and only `n af 5` shows; `⚡` shrinks to 40pt. Disabled (0 meals),
the button is an outline, not a pale filled block, so it doesn't dominate the
screen.

Default sort is curated editorial order, seasonally weighted — not alphabetical,
not newest. The first screenful has to look like dinner.

### States

| State | Design |
|---|---|
| **Loading (cold)** | 3 skeleton cards, image block + two grey bars. No spinner. |
| **Loading (more)** | Skeleton card appended at the bottom of the scroll. |
| **Empty — no filter** | Cannot happen: the curated set ships bundled with the app (§8). If it does, show the offline state. |
| **Empty — filtered** | Centered: **"Ingen retter matcher alle filtrene."** Body: "Prøv at fjerne ét filter." Button: `Nulstil filtre`. |
| **Error** | Inline banner above the chip row: "Kunne ikke opdatere opskrifterne." with `Prøv igen`. Bundled recipes stay visible and fully usable underneath — **never** a full-screen error over a working list. |
| **Offline** | Same as error, banner copy: "Du er offline. Viser dine gemte opskrifter." Import icon dims to 40%; tapping it shows toast "Import kræver forbindelse." |
| **Selection at 7** | Tray reads `7 af 5 · Byg sedlen`. ＋ on unselected cards dims; tap shows toast "Syv er hele ugen — fjern én først." (`pick.maxToast`). No hard lock, no modal. The cap applies to every add path (§3, §4, §7); `Byt` is never blocked. |

---

## 3. Recipe Sheet

Half-height modal, drag to full. Reached from any card in Opskrifter (or the swap picker) or a Plan row.

```
┌──────────────────────────────────────┐
│ ─────                                │  drag handle
│ [           hero image           ]   │
│                                      │
│ Kylling i karry                      │
│ 25 min · Nem · kr · 🧒 Børnevenlig   │
│ Indisk · til 4 personer              │
│                                      │
│ Ingredienser                         │
│  500 g kyllingebryst i strimler      │
│  2 spsk karry                        │
│  4 dl kokosmælk                      │
│  … (hele listen, skaleret)           │
│                                      │
│ Fremgangsmåde                        │  curated: numbered steps, expanded
│  1. …                                │
│                                      │  imports: "Fremgangsmåde · Se den
│ Fra valdemarsro.dk ↗                 │  på {domain} ↗" (link row)
├──────────────────────────────────────┤
│      ＋  Tilføj til denne uge        │  pinned; ✓ Fjern if selected
└──────────────────────────────────────┘
```

- Ingredient quantities render **scaled to household servings**, with a quiet
  `til 4 personer` label so the user knows why the numbers differ from the
  source. Fractions display Danish-style: `½ dl`, and decimals use a comma
  (`1,5 dl`), never a point.
- Method is shown **expanded**, as numbered steps (rev 5; it was collapsed). The
  sheet is already a detail view, so one more tap bought nothing. v1 still isn't
  a cooking-mode app (§10).
- Imported recipes show source attribution with an outbound link. Curated show
  nothing.
- Imported recipes store **no method text** (ADR 0010). In place of the method,
  a full-width link row reads **Fremgangsmåde · Se den på {domain} ↗**
  (`recipe.methodLink`) and opens the source. Pasted-text imports have no
  source and show no method row.
- Imported recipe images are hotlinked from the source and cached on the
  phone; missing or broken → an authored placeholder illustration
  (`ImportTile`) in the same footprint.
- `Tilføj til denne uge` is disabled at 7 meals; tapping it shows
  `pick.maxToast`.

**States:** loading = skeleton at same layout. Error fetching detail = sheet
shows title/meta from the card plus "Kunne ikke hente hele opskriften." +
`Prøv igen`; `Tilføj til denne uge` **stays enabled** — we already have enough to plan with.

---

## 4. Weekly Plan

Tab 1. The review-and-adjust surface.

```
┌──────────────────────────────────────┐
│  Denne uge                    ⚙      │
│  5 måltider · til 4 personer         │
├──────────────────────────────────────┤
│ ┌──┐ Kylling i karry              ⋯ │  PlanRow, 72pt tall
│ │▣ │ 25 min · kr                    │  · 56pt thumbnail
│ └──┘                                 │  · ⋯ → Fjern / Byt / Antal
│ ┌──┐ Pølse-orzo i én gryde        ⋯ │
│ │▣ │ 30 min · kr                    │  Swipe-left = Fjern (with Undo
│ └──┘                                 │  toast, 5s). Swipe is a shortcut,
│ ┌──┐ Tacos med sorte bønner       ⋯ │  never the only path.
│ │▣ │ 20 min · kr · til 6            │  ← per-recipe serving override
│ └──┘                                 │    shown inline when ≠ household
│                                      │
│  ＋ Tilføj et måltid                 │  → switches to Opskrifter
├──────────────────────────────────────┤
│        Se indkøbssedlen  ▸           │
└──────────────────────────────────────┘
```

- `⋯ → Byt` opens the picker **as a modal** pre-filtered to the same time band and cost band as the
  meal being replaced, and removes the old meal on selection. One gesture,
  like-for-like.
- Changing servings anywhere invalidates the list; see §5 stale state.
- `⚙` → `Antal personer`, `Mine basisvarer` (§5), `Log ind` (or `Log ud` when
  signed in), `Slet konto` (signed in only), `Ryd ugen`.
- `Ryd ugen` opens a confirm dialog (`week.clear.*`). It clears meals, item
  states, the list and hand-added items; it keeps household servings,
  personal staples and imported recipes (ADR 0004).
- `Log ud` and `Slet konto` each confirm first (`auth.signOut.*`,
  `auth.delete.*`; ADR 0006).

### States

| State | Design |
|---|---|
| **Empty** | Centered illustration. **"Ingen måltider endnu."** Body: "Vælg et par, så bygger vi sedlen." Primary: `Vælg måltider` → Opskrifter. Secondary: `⚡ Overrask mig` → fills 5 and lands on List. |
| **Loading** | Only right after sign-in while the account's week downloads: 3 skeleton rows. A locally-held week renders instantly. |
| **Error** | Signed in only. Local week always renders. Banner: "Kunne ikke gemme din uge." + `Prøv igen`. Edits queue locally. |
| **Offline** | Fully functional. Footer chip: `Offline — ændringer er gemt på telefonen`. |

---

## 5. Grocery List

Tab 2. Priority #2 — the screen people live in.

```
┌──────────────────────────────────────┐
│  Indkøb                 ＋   ⤴   ⋯   │  ＋ = Tilføj en vare, ⤴ = Del
│  24 varer · 5 måltider               │  ⋯ = Fjern alle flueben
├──────────────────────────────────────┤
│  FRUGT & GRØNT                    6  │  AisleHeader, sticky
│   ○  3 løg                           │  ItemRow, 52pt
│      Fra 3 retter ⌄                  │  ← merged: tap expands the
│   ○  500 g gulerødder                │    per-recipe breakdown inline
│      Fra 2 retter + dig ⌄            │
│      1 bundt forårsløg  [Skal købes] │  ← optional line, skipped: no
│      Valgfri i opskriften            │    checkbox, one labelled action
│  MEJERI & KØL                     4  │
│   ○  2 dl crème fraiche              │
│  KØD & FISK                       3  │
│   ○  500 g kyllingebryst             │  ◀ swipe: Spring over · Basisvare · Ret mængde
│   ○  400 g pølser                    │
│  ⌃  Basisvarer du sikkert har (5)    │  ← group at the bottom
│      salt               [Skal købes] │
│      2 spsk olie        [Skal købes] │
├──────────────────────────────────────┤
│         🛒  Start indkøbet           │  → In-Store mode
├──────────────────────────────────────┤
│   Plan      Liste      Opskrifter    │
└──────────────────────────────────────┘
```

**Rules**

- **Aisle order is walking order in a Danish discount supermarket** (Rema 1000 /
  Netto / Føtex layout), not alphabetical and **not the rev-1 UK order**:
  `FRUGT & GRØNT → BRØD → KOLONIAL → MEJERI & KØL → KØD & FISK → FROST →
  DRIKKEVARER → HUSHOLDNING → ANDET`. Produce and bread sit at the entrance,
  dry goods run through the middle aisles, chilled and meat along the back wall,
  freezers after them, drinks and non-food by the tills. Fixed order, ships as a
  constant. → *Tradeoff: one order for every chain. A Bilka
  walk differs, but a wrong-by-one-aisle order still beats alphabetical.*
- **Merged lines are the product.** A row built from more than one source shows
  a text line under the item: **`Fra {n} retter ⌄`** (`list.merged.recipes`),
  `Fra {n} retter + dig` when a hand-added amount is included
  (`list.merged.recipesAndYou`). Tapping it expands the breakdown **inline**
  under the row — "Pølse-orzo · 300 g", "Tacos med sorte bønner · 200 g",
  "Tilføjet af dig · 2" — and tapping again collapses it. *Rev 5:* this replaces
  the `ⓘ2` / `≡ 2` badge, which reviewers couldn't read, and the popover, which
  clipped inside swipeable rows. This is the moment the app looks smart; make it
  discoverable but not noisy.
- **Staples default off, not hidden.** Salt, olie, almindelige krydderier — and
  the household's **personal staples** — render in a collapsed
  `Basisvarer du sikkert har` group and start **skipped**. Never silently
  omitted — a missing ingredient is the one bug that loses trust. Expanding is
  one tap. Optional lines also start skipped but stay in their aisle, with the
  sub-line `Valgfri i opskriften` (`list.optionalHint`).
- **Skipped rows have no checkbox** (rev 5). They show one labelled button,
  **`Skal købes`** (`list.need`); tapping it or the row moves the item to to-buy
  in its own aisle, with the undo toast "{item} er sat på sedlen."
  (`list.needToast`). **A tick always means bought.** For a personal staple,
  `Skal købes` applies to this list only; it stays a personal staple.
- **`＋` in the header → `Tilføj en vare`** (rev 5; it was hidden in `⋯`). `⋯`
  keeps only `Fjern alle flueben`. The sheet takes free text, parsed as
  `[mængde] [enhed] navn`:
  - quantity accepts comma or point decimals and `½`; the unit may be glued or
    abbreviated: `500g kartofler`, `1,5kg kartofler`, `500 gr kartofler`,
    `2 stk. løg` all parse; a quantity with no unit means `stk`;
  - the name is matched against the ingredient table (key, plural or alias,
    case-insensitive);
  - **match** → the item joins that ingredient's row like a recipe line, sums
    within the same unit family (V2/V3 apply) and the row goes to to-buy; the
    toast reads "Lagt sammen: {row}" (`list.addItem.merged`) or "{row} er
    tilføjet under {aisle}." (`list.addItem.added`);
  - **no match** → a free-text row in `ANDET`, as before;
  - a live hint under the field says what will happen:
    `Står allerede på sedlen: {row}. Vi lægger det sammen.` /
    `Kommer under {aisle}.` / `Den kender vi ikke — den kommer under ANDET.`
    (`list.addItem.hint.*`).
  Adding an item **never applies pending week changes**: it is merged into the
  list as built, so a stale list stays stale (ADR 0018 V21).
- **Swipe left on a row** (rev 5) reveals actions; a tap anywhere closes them.
  Every action is also exposed as a **VoiceOver / TalkBack custom action** on
  the row — swipe is a shortcut, never the only path.
  - **`Spring over`** (`list.swipe.skip`) — the row goes to skipped **on this
    list only**: it stays in its aisle, greyed, with the sub-line `Springes
    over denne gang` and its `Skal købes` button (a staple goes back into
    `Basisvarer`). This is also the way back after `Skal købes`. Undo toast
    "{item} springes over denne gang." (`list.swipe.skipToast`).
  - **`Basisvare`** (`list.swipe.have`) — the row goes to skipped and moves into
    `Basisvarer`, and the ingredient becomes a **personal staple** (undo toast
    "{item} er nu en af dine basisvarer.", `list.swipe.haveToast`).
  - **`Ret mængde`** (`list.swipe.qty`) — a sheet with `−` / `+` around the
    current amount (steps: 50 g/ml, ½ kg/l/dl/spsk/tsk, else 1) and `Gem`. The
    row then shows `Rettet af dig` (`list.qty.edited`) and the sheet offers
    `Brug opskrifternes mængde` (`list.qty.reset`). The override holds until the
    recipe-derived amount for that row changes; then it is dropped and the new
    amount shows (V22). On a row with joined amounts it edits the first part.
    Raising the amount on a bought row returns it to to-buy.
  - **`Fjern`** (`list.swipe.remove`) — only on hand-added `ANDET` rows; undo
    toast.
- **Personal staples** (rev 5). `⚙ → Mine basisvarer` (`settings.myStaples.*`)
  lists them with `Fjern`. They start skipped on every new list (V23), survive
  `Ryd ugen`, belong to the household, and sync like household servings.
- **Stale banner.** If a meal was added or removed, or household or per-meal
  servings changed, since the list was built: amber strip at top — "Din uge er
  ændret." + `Opdatér sedlen`. Item-state changes and hand-added items never
  make the list stale. Never silently recompute under someone standing in a
  shop. *Exception:* arriving after `Gem og tilføj` on an import rebuilds
  automatically if nothing is bought yet (ADR 0018 V9).
- **The list is built on the phone** by one pure function over local data
  (ADR 0002). Building never needs the network.

**List-building rules** (ADR 0018)

- **Three item states:** to buy ○ / bought ✓ / skipped (no checkbox;
  `Skal købes`).
- **Item identity (V1):** a row's key is ingredient (canonical or local) + unit
  family (weight / volume / its own unit). States carry over to a rebuilt list
  by key. If a bought row's amount goes up on rebuild, it returns to to-buy.
  Hand-added items have their own id and always carry over; they are cleared
  only by `Ryd ugen`. A hand-added item that matches an ingredient keys into
  that ingredient's row (V20). `Fjern alle flueben` returns bought rows to to-buy and
  leaves skipped rows alone.
- **Non-convertible units for one ingredient (V2)** → one row with joined
  amounts: `300 g + 2 stk gulerødder`. One tap checks it; `Fra {n} retter` shows the sources.
- **Display unit (V3):** the ingredient's `default_unit` if it's in the same
  family, else the largest unit that keeps the number ≥ 1. `4 dl` never shows
  as `400 ml`; `1500 ml` shows as `1,5 l`.
- **Rounding after scaling (V4):** `dåse`, `pakke`, `bundt`, `fed`, `skive` →
  up to a whole number; `stk` → up to the nearest ½; `dl`, `spsk`, `tsk` →
  nearest ½; `g` → nearest 5 below 100 g, nearest 25 from 100 g. Shown as ½ ¼ ¾
  where exact, else a comma decimal. **Never scaled (V5):** `knivspids` and
  lines with no quantity.
- **Plurals (V6):** plural only if the ingredient `pluralises` and the quantity
  is not null and not exactly 1. `stk` is never shown: `3 løg`, not `3 stk løg`.
- **Size words (V7)** (`store`, `små`, …) are preparation and ignored when
  merging: `2 store løg` + `1 løg` → `3 løg`.
- **Rev 5 rules (V20–V24):** hand-added items merge into ingredient rows (V20);
  adding an item never applies pending week changes (V21); quantity overrides
  drop when the recipe-derived amount changes (V22); personal staples start
  skipped (V23); a skipped row has no checkbox and `Skal købes` is its only
  action (V24).

### States

| State | Design |
|---|---|
| **Empty (no meals)** | **"Der er ikke noget at købe endnu."** Body: "Vælg nogle måltider, så bygger sedlen sig selv." Primary: `Vælg måltider`. |
| **Loading (first build)** | Aisle headers render as grey bars with 2–4 skeleton rows each — the *shape* of a list appears immediately so the wait reads as progress. |
| **Error** | Full-screen only if the build fails and no list was ever built: "Kunne ikke bygge din seddel." + `Prøv igen` + `Tilbage til din uge`. If a previous list exists, show it plus a banner. |
| **Offline** | Full function, including building and `Opdatér sedlen`. Chip: `Offline`. Check-offs persist locally. |
| **Partial** | A meal whose recipe isn't on this phone yet (e.g. right after sign-in, before imports have downloaded). The list builds without it; banner "1 måltid er ikke hentet til telefonen endnu." (`list.partial`) + `Se hvilket` → names it, offers `Fjern fra ugen`. |

---

## 6. In-Store Mode

Full-screen takeover. Priority #4 — one-handed, in a shop, holding a child.

```
┌──────────────────────────────────────┐
│  ✕ Færdig            8 af 24         │
│  ████████░░░░░░░░░░░░░░░░░░░░        │  progress bar
├──────────────────────────────────────┤
│                                      │
│   FRUGT & GRØNT                      │  Type scale up ~35% from List.
│                                      │  Row height 64pt. Full-width
│   ○   3 løg                          │  tap target — the whole row,
│                                      │  not the checkbox.
│   ○   2 limefrugter                  │
│                                      │  Checked items animate out and
│   ○   500 g gulerødder               │  collapse into a "Færdige (8) ⌄"
│                                      │  group at the very bottom.
│   KØD & FISK                         │
│                                      │  Screen stays awake.
│   ○   500 g kyllingebryst            │  No pull-to-refresh (misfires
│                                      │  constantly with one thumb).
│   ⌄  Færdige (8)                     │
└──────────────────────────────────────┘
```

- **Visual style: a fixed dark screen** (dark ground, light type), decided in
  rev 5 from the v2 design. It marks the mode change and cuts glare in a shop.
  It is one screen's style, not a theme — §10's "no dark mode" is about an app
  theme and still stands.
- Single-column, one aisle visible at a time as you scroll. No thumbnails, no
  merge badges, no metadata — everything that isn't "what do I put in the
  trolley" is gone.
- Shows only **to-buy and bought** rows; skipped staples and optional lines are
  not shown. `8 af 24` counts to-buy + bought.
- Checking is **optimistic and local-first**, always. Sync happens quietly.
- Undo: tap the row again in the `Færdige` group, or a 5s toast.
- On last item checked: brief celebratory state — **"Så er der købt ind."** with
  `Færdig` — then back to List. The one-time optional sign-in offer (§8) may
  appear **on the List** after this, never in in-store mode.
- `✕ Færdig` exits and keeps all checks.

**States:** no loading state (the list is already in hand). **Offline is the
default assumption** — supermarkets have no signal, so this screen never shows a
network error, never blocks a tap on a request, and shows no offline chip.
Everything queues. Error state: none by design.

---

## 7. Recipe Import + Review

Priority #3. Two entry points: `🔗 Importér` in Opskrifter, and the OS share sheet from
a browser.

> **Superseded by [`docs/product/import-review-design.md`](import-review-design.md)
> (ported from v2, ADR 0015).** Rev 4 adds: parsing works anonymously
> (rate-limited, ~5/day per device, higher when signed in); an unsaved draft is
> kept 7 days if the user backs out. *Rev 5:* `Gem` never asks for sign-in — a
> saved import lives on the phone and uploads at first sign-in (ADR 0006
> amended 13 Nov 2026); slow parses soften at 12 s and offer paste-text at 25 s; `Gem og tilføj`
> with 7 meals in the week saves only and shows the cap toast; a daily-limit
> state (D-6) exists. What follows is the
> original sketch, kept for the reasoning. The buildable version differs in four
> ways, all driven by contracts that landed after this was written: the parsing
> state shows the *real* title and image at ~1s (two-stage partial import body)
> instead of a shimmer; flagged rows carry a specific plain-language reason drawn
> from the parser's four sub-scores and the fix sheet opens focused on the wrong
> field; missing required meta (servings) joins the same `Check these` queue
> rather than getting its own blocking UI; and there is no hard 15s timeout —
> slow parses soften and offer paste-text while still running. Build from the
> design doc.

### 7a. URL entry

```
┌──────────────────────────────────────┐
│  ✕         Importér en opskrift      │
│                                      │
│  Indsæt et link fra en opskriftsside.│
│  ┌────────────────────────────────┐  │  Autofocus. If the clipboard
│  │ https://                       │  │  holds a URL, prefill it and
│  └────────────────────────────────┘  │  select-all.
│                                      │
│             Importér ▸               │
│                                      │
│  Eller indsæt opskriftens tekst      │  ← always available, not just
│                                      │    an error fallback
└──────────────────────────────────────┘
```

### 7b. Parsing

```
┌──────────────────────────────────────┐
│  Læser valdemarsro.dk…               │
│                                      │
│      [ shimmer: title bar ]          │  Progressive: the skeleton fills
│      [ shimmer: 3 meta pills ]       │  in as fields arrive, so a 4s
│      [ shimmer: 8 ingredient rows ]  │  wait shows continuous motion.
│                                      │
│               Annullér               │
└──────────────────────────────────────┘
```

`Annullér` is always present. ~~Hard timeout 15s → error state 7d-2.~~ *Rev 4:
no hard timeout — soften at 12 s, paste-text at 25 s (import design §2).*

**Danish sites, specifically (input to the parser epic).** The demo will be imported from
`valdemarsro.dk`, `arla.dk`, `madensverden.dk`, `rema1000.dk/opskrifter`,
`opskrifter.dk`. Most are WordPress with JSON-LD `Recipe` markup, which is the
good path. Three things the pipeline must handle that a `en-GB` pipeline would
not:
1. **Comma decimals** — `1,5 dl` is one and a half, not fifteen.
2. **Danish unit tokens** — `spsk`, `tsk`, `dl`, `stk`, `fed`, `bundt`, `dåse`,
   `pakke`, `knivspids`, `nip`, `skive`, and the bare `en smule`.
3. **Danish extraction prompting** — the Claude fallback must be instructed in
   and return Danish ingredient names, so they match the canonical ingredient
   table and merge with the curated set. An English-normalising parser silently
   breaks every merge.

### 7c. Review & Confirm — the screen that has to feel trivial

**The core idea: don't ask the user to audit 14 lines. Ask them to fix 2.**
The parser returns a per-line confidence. Low-confidence lines are hoisted into a
`Check these` group at the top; everything else sits below, already correct.

```
┌──────────────────────────────────────┐
│  ✕            Tjek importen          │
│  ┌────────────────────────────────┐  │
│  │ Kylling i karry             ✎  │  │  title, tap to edit
│  │ 25 min ✎ · til 4 personer ✎    │  │  each meta field tap-to-edit
│  └────────────────────────────────┘  │
│                                      │
│  TJEK DISSE 2                        │  amber section header
│  ┌────────────────────────────────┐  │
│  │ ● 1  bundt  forårsløg       ✎ │  │  amber dot = low confidence
│  │      "et bundt forårsløg"      │  │  ← source line, always shown
│  └────────────────────────────────┘  │     beneath a flagged row
│  ┌────────────────────────────────┐  │
│  │ ● —  —  salt og peber       ✎ │  │  unparseable qty shown as —
│  │      "salt og peber efter smag"│  │  Actions: Ret · Spring linjen over
│  └────────────────────────────────┘  │
│                                      │
│  SER FINE UD 12                 ⌄    │  collapsed by default
│                                      │
├──────────────────────────────────────┤
│    Gem og tilføj til denne uge       │  primary
│            Gem kun                   │  secondary text button
└──────────────────────────────────────┘
```

**Editing a line — the whole point of the screen:**

```
┌────────────────────────────────┐
│  1      bundt ⌄   forårsløg    │  Three fields in a row.
│ ┌───┐  ┌──────┐  ┌───────────┐ │  · qty: numeric keypad, opens
│ │ 1 │  │bundt │  │forårsløg  │ │    with the value selected
│ └───┘  └──────┘  └───────────┘ │  · unit: picker wheel, recent
│                                │    units first, "ingen enhed" top
│  ½  1  2  3   ← hurtig mængde  │  · item: text, autocompletes
│                                │    against the ingredient table
│  Spring linjen over   ✓ Færdig │
└────────────────────────────────┘
```

- Fractions matter: quick-qty pills offer `½ 1 2 3` and the keypad accepts
  `1/2`, `,5` **and** `.5`. On a Danish keyboard the decimal key is a comma, so
  a field that only parses `.` rejects everything a Danish parent types — this is
  the single highest-traffic locale bug in the flow. Display always uses the
  comma (`1,5 dl`); storage is a decimal.
- `Spring linjen over` is prominent. Dropping a line is a legitimate, fast answer —
  far better than forcing a bad guess into the grocery list.
- Fixing a flagged line moves it into `Ser fine ud` with a soft transition; the
  header counts down `TJEK DISSE 1`. Progress is visible.
- `Gem og tilføj til denne uge` is **never blocked** by open flags (decided in
  rev 5 after the draft review). Lines that have an ingredient but an open flag
  (range, dropped unit, guessed amount) save with the parser's value. A line
  whose ingredient is still unknown is **kept as a new local ingredient** under
  its parsed name, in the aisle the parser proposed or `ANDET`, marked `NY VARE`
  (decided 13 Nov 2026; ADR 0003 amended): a missing ingredient on the list costs
  more trust than an oddly sorted one. Only lines the user taps `Spring linjen
  over` on are dropped, and the button subtitle counts those: "2 linjer springes
  over." Explicit consequence, no gate.
- Ingredient-name autocomplete against the canonical ingredient table is what
  makes an imported recipe merge cleanly with curated ones — this is a hard
  requirement on the data-model and content epics, not a nicety.

### 7d. Import error states

Three genuinely different failures. Each gets its own copy and its own next step.

**7d-1 · Not a recipe page** — page loaded, no ingredients found.
```
   🍽 (empty plate)
   Det ser ikke ud som en opskrift.

   Vi åbnede siden, men kunne ikke finde
   en ingrediensliste på den.

   [ Prøv et andet link ]
   [ Indsæt opskriftens tekst i stedet ]
```

**7d-2 · "Vi kunne ikke læse denne side"** — fetch failed, blocked, paywalled,
timeout. *(The "we couldn't read this page" case the brief calls out.)*
```
   🔒
   Vi kunne ikke læse denne side.

   Nogle sider lukker os ikke ind. Indsæt
   opskriftens tekst, så klarer vi resten.

   [ Indsæt opskriftens tekst ]     ← primary
   [ Prøv igen ]
   [ Prøv et andet link ]
```
The paste-text fallback is the primary action, not a footnote. It is the escape
hatch that means import *never* fully fails, and it routes through the same
extraction pipeline (raw text in, structured recipe out — ADR 0012).

**7d-3 · Not a URL** — inline, under the field, no screen change:
"Det ser ikke ud som en webadresse." Import button disabled.

**7d-4 · Offline** — Import is unreachable from Picker while offline (icon
dimmed + toast). If connectivity drops mid-parse: "Forbindelsen blev afbrudt." +
`Prøv igen` (retries the same URL) + `Indsæt opskriftens tekst`.

**7d-5 · Already imported** — skip parsing entirely, go straight to Recipe Sheet
with a toast: "Den har du importeret før."

### Paste-text mode

Same review screen, same pipeline. Multi-line textarea, placeholder:
"Indsæt ingredienser og fremgangsmåde her." Title field shown separately since
pasted text often lacks a clear one.

---

## 8. Cross-cutting

| Concern | Decision |
|---|---|
| **Bundled recipes** | The **44** curated recipes, the canonical ingredient table and their images ship in the app bundle. The picker is therefore *never* empty and never blocked on a network call. A background delta sync (`?updated_since=`, with tombstones) refreshes them. |
| **Sign-in** | **Email + 6-digit one-time code**; sign-up = sign-in; no passwords (ADR 0005). Anonymous use covers pick → plan → list → in-store completely. Sign-in is **never required**: import, including `Gem`, works without an account (parsing is rate-limited per device; rev 5, ADR 0006 amended). Without an account, imported recipes, new local ingredients and personal staples live **on the phone only** and are lost if the app is deleted. Sign-in is **offered once** after the first "Så er der købt ind", on return to List: "Gem jeres uge? Log ind, så er den der på enhver telefon." with `Ikke nu`, which silences it. Never in in-store mode, never before a share, never in onboarding. `⚙ → Log ind` is always there. First sign-in uploads the week, item states, household servings, personal staples, and any anonymous imports and local ingredients (an import whose URL the account already has is dropped in favour of the account's copy); if phone and account both have a week, ask once which to keep (ADR 0006). |
| **Account** | `⚙ → Log ud` (confirm; account data is wiped from the phone). `⚙ → Slet konto` (confirm; hard-deleted within 30 days; the phone keeps its local week as anonymous). |
| **Offline posture** | Pick, plan, **list building** and in-store are fully offline. The list is built on the phone (ADR 0002). Import and sign-in are the only network-required flows. In-store mode assumes no signal. |
| **Loading** | Skeletons that match final layout, never spinners, never blocking modals. Anything over 400ms gets a skeleton; anything over 10s gets a cancel. |
| **Errors** | Banner over cached content wherever cached content exists. Full-screen error only when there is genuinely nothing to show. Every error names one concrete next action. |
| **Toasts** | **Undo toasts 5s; all others 4s.** Bottom, above the tray/CTA. Used for undo and for soft limits. Never for errors that need a decision. |
| **One-handed reach** | Every primary action sits in the bottom third. Nothing destructive in the top bar. Minimum 44pt targets; 64pt in in-store mode. |
| **Type** | Body 17pt min; in-store rows 22pt. Supports Dynamic Type to XL without layout breaking. **Danish runs ~15% longer than English** and compounds ("indkøbsseddel", "Basisvarer du sikkert har") — every label must be specced to wrap or truncate, and no button copy may rely on fitting one line at XL. The onboarding servings control is a 4×2 grid so it fits at 320pt with XL type (rev 5). The picker tray at 320pt with XL type is still open (§2, §11). |
| **Handoff** | `⤴` on the List = OS share sheet (plain text, aisle-grouped, to-buy items only) + `Kopiér`. `Gem som note` is removed: iOS has no public API for it, and the share sheet reaches Notes and Reminders. **No direct basket integration in v1** — the DK spike (UMA-15) found Instacart and Kroger don't operate in DK and nemlig.com publishes no API (its internal backend is out of bounds under `robots.txt` plus Queue-it). Basket handoff is **parked as a later feature** (ADR 0001), not a v1 dependency. Share/export + in-store check-off is the handoff. |
| **Privacy** | Crash reports go to Sentry (EU) with no personal data. A small, fixed set of anonymous counts goes to our own API — no device ID, no stored IP. No third-party analytics. The LLM never receives personal data. **Legal check before release** (ADR 0017). |
| **Haptics** | Light tick on add/remove and on check-off. That's it. |

---

## 9. Recipe metadata the picker needs

Input to the data-model and content epics. Everything here is either displayed
on a card, filterable, or needed to build the list.

### Recipe

| Field | Type | Req | Used by | Notes |
|---|---|:--:|---|---|
| `id` | uuid | ✔ | all | |
| `title` | string(80) | ✔ | card, sheet | Truncates at one line on cards. |
| `hero_image` | url | ✔ curated | card, sheet | 16:9. Curated set needs one for all **44** — a card without an image is unusable. Imports: nullable; the source image URL only, hotlinked and cached on the phone, never copied (ADR 0010). |
| `total_time_min` | int | ✔ | card, filter | Single number. Prep/cook split is not shown in v1. |
| `time_band` | derived | — | filter | **Derived on the fly** from `total_time_min` by one shared function, **never stored** (ADR 0014). `≤20` / `21–30` / `31+`. The `Under 30 min` chip = `≤ 30`. Null time → null band, matches no time chip. |
| `difficulty` | enum | ✔ | card, filter | `easy` \| `medium`. No `hard` — nothing hard belongs in a Tuesday family set. |
| `kid_friendly` | bool? | ✔ curated | card badge 🧒, filter | Nullable: `null` for imports (we can't judge). Filter treats null as excluded. |
| `cost_band` | enum | ✔ | card, filter | `low` \| `mid` \| `high`, rendered `kr` / `kr kr` / `kr kr kr`. Editorial judgement, not a computed price — no price data in v1. *Design note: `kr kr kr` is 8 characters against `£££`'s 3. On the compact card MetaRow at 320pt, cost band is the first element to drop; it is never the reason the title truncates.* |
| `cuisine` | enum | ✔ | sheet, filter | Fixed list, **DK set**: `dansk`, `nordisk`, `italiensk`, `mexicansk`, `indisk`, `asiatisk`, `mellemøstlig`, `amerikansk`, `middelhav`, `andet`. Single value. Keys are the Danish words — this is a single-locale app and an English key layer buys nothing. `british` is gone; `chinese`/`japanese`/`thai` collapse into `asiatisk`. → *Tradeoff: at 44 recipes, three separate Asian cuisines split the filter too thin to be useful.* |
| `seasons` | enum[] | ✔ | sort weight | `forår`\|`sommer`\|`efterår`\|`vinter`\|`altid`. Drives default sort, exposed as a filter in the `Mere` sheet. |
| `servings_default` | int | ✔ | scaling | The servings the ingredient quantities are written for. Required for correct scaling. |
| `tags` | enum[] | — | filter sheet, badges | `one_pot`, `sheet_pan`, `vegetarian`, `vegan`, `freezer_friendly`, `no_cook`, `leftovers_good`, `air_fryer`. Closed set — free tags rot. |
| `pantry_light` | bool | — | sort weight | True when ≤2 ingredients are outside the common-staples set. Powers "doesn't need a special shop". |
| `source` | enum | ✔ | sheet | `curated` \| `imported`. |
| `source_url` | url? | ✔ imports | sheet attribution | |
| `source_name` | string? | ✔ imports | sheet attribution | Display domain, e.g. `valdemarsro.dk`. |
| `method_steps` | string[] | — | sheet | **Curated only.** Collapsed by default. Imports store none (ADR 0010, §3). |
| `sort_weight` | int | — | default order | Editorial ordering for the curated set. Manual, admin-editable. |
| `created_at` | ts | ✔ | "Only my imports" | |
| `owner_id` | fk? | ✔ imports | ownership | Null for curated; the account for imports. Saved imports are always account-owned (ADR 0006). |
| `raw_source_text` | text? | — | re-parse, debugging | Pasted-text imports only. Private to the owner; never displayed. |

### Ingredient line

| Field | Type | Req | Notes |
|---|---|:--:|---|
| `id` | uuid | ✔ | |
| `recipe_id` | fk | ✔ | |
| `position` | int | ✔ | Source order; the review screen must preserve it. |
| `quantity` | decimal? | ✔ | Nullable ("salt efter smag"). Must hold `0.5`, `0.25`, `0.333`. Stored as a decimal point; **parsed from and displayed with a Danish comma**. |
| `unit` | enum? | ✔ | **DK set:** `g`,`kg`,`ml`,`dl`,`l`,`tsk`,`spsk`,`stk`,`bundt`,`fed`,`dåse`,`pakke`,`knivspids`,`skive`, null. Closed set — the consolidation engine can't normalise open strings. Changes from rev 1: **`dl` added** (Danish recipes measure liquid in dl, not ml, and `4 dl` must not display as `400 ml`); **`cup` removed** (does not exist in DK recipes); `tsp`/`tbsp`/`piece`/`bunch`/`clove`/`can`/`pack`/`pinch`/`slice` renamed to their Danish tokens. Display = the key. Merge rules: `dl`↔`ml`↔`l` and `g`↔`kg` convert; everything else merges only within its own unit. |
| `ingredient` | fk | ✔ | → canonical **or** local Ingredient. **Never null** after review (ADR 0003). **The join that makes merging work.** |
| `preparation` | string? | — | "finely diced". Shown in the sheet, ignored by the list. Size words (`store`, `små`) go here and don't affect merging. |
| `raw_text` | string | ✔ | The original Danish line. Displayed under flagged rows in review; kept forever for debugging. |
| `confidence` | decimal? | ✔ imports | 0–1. Drives the `Tjek disse` split. Threshold **< 0.8** → flagged; **sent by the server**, never hardcoded in the app. The full import line contract — `confidence_parts`, `ingredient_match`, `suggested_ingredients`, `dropped_unit_word`, `is_range`, `quantity_high` — is ADR 0011. |
| `is_optional` | bool | — | Optional lines start **skipped** in the list. |

### Ingredient (canonical)

| Field | Type | Req | Notes |
|---|---|:--:|---|
| `id` | uuid | ✔ | |
| `name` | string | ✔ | Singular canonical, Danish: `løg`, `gulerod`. |
| `display_plural` | string | ✔ | `løg`, `gulerødder`. **Must be authored per ingredient, never derived** — Danish plurals are irregular and often identical to the singular (`løg`→`løg`, `æg`→`æg`, `gulerod`→`gulerødder`). An `+s` rule produces nonsense here in a way it did not in rev 1. |
| `pluralises` | bool | ✔ | The plural form is used only when true and the quantity is not null and not exactly 1. |
| `aisle` | enum | ✔ | `frugt_groent`,`broed`,`kolonial`,`mejeri_koel`,`koed_fisk`,`frost`,`drikkevarer`,`husholdning`,`andet`. **This list is in walking order and the order is the spec** (§5) — DK discount-store layout, reordered from rev 1's UK order. ASCII keys (`oe`/`ae`/`aa`) so nothing depends on encoding; display strings are in §12. |
| `is_staple` | bool | ✔ | Drives the collapsed `Basisvarer` group. Danish staple set: salt, peber, olie, smør, mel, sukker, sojasovs, eddike, bouillon. |
| `default_unit` | enum? | — | Preferred unit for display after merging. Liquids default to `dl`. |
| `aliases` | string[] | ✔ | `forårsløg` / `forårsløg (grøn)` / `spring onion`. Holds Danish spelling variants **and** the English name, because a Danish site occasionally writes the English one. The import autocomplete and the merge both ride on this. |

### Local ingredient (ADR 0003)

An ingredient a user created during import review because the canonical table
had no match.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `owner_id` | fk | Always an account. |
| `name` | string | Normalised Danish name; the merge key within the account (exact match only). |
| `aisle` | enum | Proposed by the LLM, else `andet`. |
| `is_staple` | bool | Always false. |
| `curation` | enum | `pending` \| `promoted` \| `mapped`; `mapped_to` fk when mapped. Editors promote or map in Django admin. |

### Week / Plan

| Field | Type | Notes |
|---|---|---|
| `id`, `user_id` | | `user_id` null while anonymous. One open-ended week per user; no `week_start_date`, no rollover (ADR 0004). |
| `household_servings` | int | From onboarding. Default scale for every recipe. |
| `entries[]` | | `{ recipe_id, servings_override: int? }`. **No day field** (§0). |
| `list_computed_at` | ts | Local. Compared against the week's last list-affecting change (§5 stale rules) to drive the stale banner. |
| `item_states` | map | `{ item_key → { state: to_buy \| bought \| skipped, changed_at } }`. Local-first; synced when signed in, last-`changed_at`-wins. |
| `extra_items[]` | | Hand-added items `{ id, text, state, ingredient_id?, quantity?, unit? }`. With `ingredient_id` (canonical or local) the item merges into that ingredient's row (V20) and `state` is unused; without it, it is a free-text row in `andet`. `quantity` is a decimal, `unit` from the unit enum; both nullable. |
| `quantity_overrides` | map | `{ item_key → { qty, unit, base_amount } }`. Set by `Ret mængde`. `base_amount` is the recipe-derived amount (base unit) when the override was set; on rebuild the override applies only if it still matches, else it is deleted (V22). |
| `personal_staples` | set | Ingredient ids the household has marked `Basisvare`. Per household, not per week: survives `Ryd ugen`. Local while anonymous; synced like `household_servings` when signed in, last-write-wins per id. |

---

## 10. Not in v1

Cut deliberately, all real, none needed for the first convincing loop:

- **Day-of-week assignment** and calendar view
- **Pantry inventory** — "what's in my cupboard"
- **Household sharing** — two parents on one week
- **Nutrition** — calories, macros, allergen flags
- **Price comparison** and total-cost estimates
- **Photo/OCR import** from cookbooks; **video import** (TikTok/Reels). The
  import pipeline takes these as future input adapters (ADR 0012).
- **Cooking mode** — step-by-step, timers, screen-on-while-cooking
- **Multiple saved weeks** / plan history / favourites & collections
- **Recipe editing** after import save (delete and re-import instead)
- **Store-specific aisle ordering** (one fixed order for everyone)
- **Accounts beyond simple sign-in** — no profiles, **no social features**
  (sharing, following, comments), no onboarding quiz. Social *login* is listed
  separately below.
- **Push notifications** of any kind
- **Dark mode** — light only in v1
- **Localisation** — `da-DK` only. Danish UI, metric with `dl`, `kr` cost bands,
  comma decimals, one Danish aisle order. **No English UI in v1**, no
  locale switch, no store-specific aisle order. Strings live in a single
  `da.ts` so a future English build is a translation job, not a refactor.
- **Direct basket handoff / third-party grocery integration** (nemlig / Salling /
  Coop / Instacart) — **parked as a later feature** (ADR 0001; no public API
  exists today, per UMA-15). Share/export plus in-store check-off *is* the v1
  handoff, and in a DK discount shop the check-off mode is the better fit
  anyway.
- **Payments, subscriptions, paywall, pricing tiers** (ADR 0001)
- **SKU matching / grocery catalog / per-product prices** (ADR 0001)
- **Browser extension** (ADR 0001)
- **Meal types** — dinner only (ADR 0001)
- **Web client** — iOS first, Android follows, no web (ADR 0008)
- **Sign in with Apple / Google** — v1.1 candidate (ADR 0005)
- **Passwords** (ADR 0005)
- **Week rollover / week history** — v1.1 candidate: "Start en ny uge?" after
  "Så er der købt ind" (ADR 0004)
- **`Grupper efter opskrift`** on the List (ADR 0018 V17)
- **`Gem som note`** (ADR 0018 V16)
- **Third-party product analytics** and consent screens (ADR 0017)
- **Storing method text or copying images** from imported recipes (ADR 0010)

---

## 11. Open questions

None open from rev 5.

Nothing else blocking. The legal check on telemetry (ADR 0017) and hero-image licensing
for the curated set (ADR 0016) are tracked as milestones, not spec questions.

### Answered

- **Picker tray at 320 pt / XL** (rev 5) — compact tray, dots hidden below
  340pt, capped type; never overflows (§2).
- **Back to skipped after `Skal købes`** (rev 5) — swipe `Spring over` (§5).
- **Unknown ingredient at `Gem`** (13 Nov 2026) — kept as a local ingredient
  under `ANDET` (or the proposed aisle), not dropped; only explicitly skipped
  lines are dropped (§7c, ADR 0003).

1. **Per-line confidence** (was Q1) — yes; the v2 contract is adopted verbatim,
   plus `is_range` / `quantity_high` (ADR 0011).
2. **Pasted text** (was Q2) — same pipeline, a different input adapter
   (ADR 0012).
3. **No-reflow and the import skeleton** (was Q3) — no-reflow is a hard
   acceptance test; the import skeleton is two-stage, not per-field (ADR 0013).
4. **`time_band`** (was Q4) — derived on the fly by a shared function, never
   stored; bands changed to ≤20 / 21–30 / 31+ (ADR 0014).

5. **Dan, 8 Sep — locale:** *"A DK family."* → the whole spec is `da-DK`.
   Consequences already folded in above: `kr` cost bands (§9), `dl` in the unit
   enum and `cup` out (§9), Danish aisle keys in DK walking order (§5, §9),
   Danish cuisine set (§9), per-ingredient Danish plurals (§9), comma decimals
   in the qty keypad (§7c), Danish extraction prompting and unit tokens (§7b),
   and Danish copy in every wireframe plus the deck in §12.
   **Downstream:** UMA-9's 40 recipes are Danish family food, not British;
   UMA-7's parser targets Danish sites; UMA-4's aisle/unit/cuisine constants
   change shape.
6. **Dan, 8 Sep — day assignment:** keep it cut. No `day` field, no calendar
   view, and optional day labels declined too.
7. **Priya, 8 Sep (via UMA-15) — market & handoff:** Denmark is the sole v1
   market, and third-party grocery integration is declined outright. Nothing in
   the spec moves: `da-DK` was already settled under (5), and share/export +
   in-store check-off were already the specced handoff. Recorded in §8
   (Handoff) and §10 (Not in v1) so the decision has a home rather than living
   in a comment thread. The one thing Priya raised that was *not* already
   implicit — "is the UI Danish or English?" — is answered explicitly in §12:
   **Danish, chrome included.** English chrome over Danish ingredients is the
   worst of the three options, not a safe default.

---

## 12. Locale & copy deck (`da-DK`)

**The decision.** Dan: *"A DK family."* So the app ships in Danish — all of it,
including the UI chrome, not just the food words. The half-measure (English
chrome, Danish ingredients) is the worst option: you would be reading
`3 løg` under a header that says `PRODUCE`, in a shop, one-handed. The list is
the screen people live in and it has to read as one language.

Every string below is the shipped string. They live in **one file, `da.ts`**,
keyed as shown — nothing hardcoded in a component. That keeps a future English
build a translation job rather than a refactor, at the cost of one indirection
the mobile epic accepts now. Glosses are for the team, not for the app.

### Aisle display strings (walking order — the order *is* the spec)

| # | Key | Displays as | Gloss |
|:-:|---|---|---|
| 1 | `frugt_groent` | **FRUGT & GRØNT** | Produce |
| 2 | `broed` | **BRØD** | Bakery |
| 3 | `kolonial` | **KOLONIAL** | Dry goods / cupboard |
| 4 | `mejeri_koel` | **MEJERI & KØL** | Dairy & chilled |
| 5 | `koed_fisk` | **KØD & FISK** | Meat & fish |
| 6 | `frost` | **FROST** | Frozen |
| 7 | `drikkevarer` | **DRIKKEVARER** | Drinks |
| 8 | `husholdning` | **HUSHOLDNING** | Household / non-food |
| 9 | `andet` | **ANDET** | Other (free-text additions land here) |

### Strings

| Key | Danish (ships) | Gloss |
|---|---|---|
| `onb.1.title` | Aftensmaden er klaret. | Dinner, decided. |
| `onb.1.body` | Vælg fem måltider. Vi samler dem til én indkøbsseddel. | Pick five meals… |
| `onb.2.title` | Alle opskrifter. Alle sider. | Any recipe. Any site. |
| `onb.2.body` | Indsæt et link, og vi trækker ingredienserne ud — så den mad, I allerede laver, passer lige ind. | Paste a link… |
| `onb.3.title` | Hvor mange laver I mad til? | How many are you cooking for? |
| `onb.3.foot` | Du kan ændre det senere. | You can change this later. |
| `common.skip` | Spring over | Skip |
| `common.retry` | Prøv igen | Try again |
| `common.cancel` | Annullér | Cancel |
| `common.done` | Færdig | Done |
| `common.offline` | Offline | Offline |
| `common.needsConnection` | Kræver forbindelse. | Needs a connection. |
| `common.close` | Luk | Close |
| `common.undo` | Fortryd | Undo |
| `common.next` | Næste | Next |
| `tab.plan` | Plan | Plan |
| `tab.list` | Liste | List |
| `tab.recipes` | Opskrifter | Recipes |
| `week.title` | Denne uge | This week |
| `week.subtitle` | {n} måltider · til {p} personer | {n} meals · serves {p} |
| `week.addMeal` | ＋ Tilføj et måltid | Add another meal |
| `week.viewList` | Se indkøbssedlen | View grocery list |
| `week.empty.title` | Ingen måltider endnu. | No meals yet. |
| `week.empty.body` | Vælg et par, så bygger vi sedlen. | Pick a few and we'll build the list. |
| `week.empty.cta` | Vælg måltider | Pick meals |
| `week.row.remove` | Fjern | Remove |
| `week.row.swap` | Byt | Swap |
| `week.row.servings` | Antal personer | Servings |
| `week.settings.clear` | Ryd ugen | Clear week |
| `settings.myStaples.title` | Mine basisvarer | My staples |
| `settings.myStaples.body` | De starter under Basisvarer på hver ny seddel. | They start under Staples on every new list. |
| `settings.myStaples.empty` | Ingen endnu. Skub en vare på sedlen til venstre, og vælg Basisvare. | None yet. Swipe an item on the list left and choose Staple. |
| `settings.myStaples.remove` | Fjern | Remove |
| `week.settings.signIn` | Log ind | Sign in |
| `week.settings.signOut` | Log ud | Sign out |
| `week.settings.delete` | Slet konto | Delete account |
| `week.clear.title` | Ryd ugen? | Clear the week? |
| `week.clear.body` | Måltider og flueben forsvinder. Jeres importerede opskrifter bliver. | Meals and checks go. Your imports stay. |
| `week.clear.confirm` | Ryd | Clear |
| `week.error` | Kunne ikke gemme din uge. | Couldn't sync your week. |
| `week.offlineChip` | Offline — ændringer er gemt på telefonen | Offline — changes saved on this phone |
| `pick.title` | Opskrifter | Recipes |
| `pick.count` | {n} retter | {n} recipes |
| `pick.countMine` | {n} retter · kun dine importerede | {n} recipes · only your imports |
| `pick.swapTitle` | Byt {title}… | Swap {title}… |
| `pick.import` | Importér | Import |
| `pick.tray` | {n} af {t} | {n} of {t} |
| `pick.buildList` | Byg sedlen | Build list |
| `pick.surprise` | Overrask mig | Surprise me |
| `pick.more` | Mere | More |
| `pick.filter.time` | Under 30 min | Under 30 min |
| `pick.filter.kids` | Børnevenlig | Kid-approved |
| `pick.filter.cost` | kr | £ |
| `pick.filter.veg` | Vegetar | Veggie |
| `pick.filter.myImports` | Kun mine importerede | Only my imports |
| `pick.emptyFiltered.title` | Ingen retter matcher alle filtrene. | Nothing matches all of those. |
| `pick.emptyFiltered.body` | Prøv at fjerne ét filter. | Try loosening one filter. |
| `pick.emptyFiltered.cta` | Nulstil filtre | Clear filters |
| `pick.error` | Kunne ikke opdatere opskrifterne. | Couldn't refresh recipes. |
| `pick.offline` | Du er offline. Viser dine gemte opskrifter. | You're offline. Showing your saved recipes. |
| `pick.importOffline` | Import kræver forbindelse. | Import needs a connection. |
| `pick.maxToast` | Syv er hele ugen — fjern én først. | Seven is the whole week — remove one first. |
| `pick.surpriseShort` | Der var kun {n} retter, der passede til filtrene. | Only {n} recipes matched your filters. |
| `recipe.ingredients` | Ingredienser | Ingredients |
| `recipe.method` | Fremgangsmåde | Method |
| `recipe.serves` | til {p} personer | serves {p} |
| `recipe.source` | Fra {domain} | From {domain} |
| `recipe.methodLink` | Se den på {domain} ↗ | See it on {domain} (shown after `recipe.method` as "Fremgangsmåde · Se den på {domain} ↗") |
| `recipe.add` | ＋ Tilføj til denne uge | Add to this week |
| `recipe.remove` | ✓ Fjern | Remove |
| `recipe.error` | Kunne ikke hente hele opskriften. | Couldn't load the full recipe. |
| `recipe.diff.easy` | Nem | Easy |
| `recipe.diff.medium` | Mellem | Medium |
| `list.title` | Indkøb | Groceries |
| `list.subtitle` | {n} varer · {m} måltider | {n} items · {m} meals |
| `list.staples` | Basisvarer du sikkert har ({n}) | Staples you probably have ({n}) |
| `list.optionalHint` | Valgfri i opskriften | Optional in the recipe |
| `list.need` | Skal købes | Need to buy |
| `list.needToast` | {item} er sat på sedlen. | {item} is on the list. |
| `list.merged.recipes` | Fra {n} retter | From {n} recipes |
| `list.merged.recipe` | Fra 1 ret | From 1 recipe |
| `list.merged.recipesAndYou` | Fra {n} retter + dig | From {n} recipes + you |
| `list.merged.you` | Tilføjet af dig | Added by you |
| `list.swipe.skip` | Spring over | Skip |
| `list.swipe.skipToast` | {item} springes over denne gang. | {item} skipped this time. |
| `list.swipe.skipped` | Springes over denne gang | Skipped this time |
| `list.swipe.have` | Basisvare | Staple |
| `list.swipe.haveToast` | {item} er nu en af dine basisvarer. | {item} is now one of your staples. |
| `list.swipe.qty` | Ret mængde | Change amount |
| `list.swipe.remove` | Fjern | Remove |
| `list.swipe.removedToast` | {item} er fjernet. | {item} removed. |
| `list.qty.title` | Ret mængde | Change amount |
| `list.qty.less` | Mindre | Less |
| `list.qty.more` | Mere | More |
| `list.qty.save` | Gem | Save |
| `list.qty.reset` | Brug opskrifternes mængde | Use the recipes' amount |
| `list.qty.edited` | Rettet af dig | Changed by you |
| `list.qty.savedToast` | Rettet: {row} | Changed: {row} |
| `list.qty.resetToast` | Mængden fra opskrifterne er tilbage. | The recipes' amount is back. |
| `list.qty.none` | Der er ingen mængde at rette. | There's no amount to change. |
| `list.startShopping` | 🛒 Start indkøbet | Start shopping |
| `list.share` | Del sedlen | Share list |
| `list.copy` | Kopiér | Copy |
| `list.addItem` | Tilføj en vare | Add an item |
| `list.addItem.body` | Skriv fx „2 gulerødder“ eller „bleer“. | Type e.g. "2 carrots" or "nappies". |
| `list.addItem.placeholder` | fx 2 gulerødder | e.g. 2 carrots |
| `list.addItem.cta` | Tilføj | Add |
| `list.addItem.hint.merge` | Står allerede på sedlen: {row}. Vi lægger det sammen. | Already on the list: {row}. We'll add them up. |
| `list.addItem.hint.aisle` | Kommer under {aisle}. | Goes under {aisle}. |
| `list.addItem.hint.unknown` | Den kender vi ikke — den kommer under ANDET. | We don't know that one — it goes under OTHER. |
| `list.addItem.merged` | Lagt sammen: {row} | Added together: {row} |
| `list.addItem.added` | {row} er tilføjet under {aisle}. | {row} added under {aisle}. |
| `list.addItem.addedOther` | {text} er tilføjet under ANDET. | {text} added under OTHER. |
| `list.clearChecks` | Fjern alle flueben | Clear checks |
| `list.stale.title` | Din uge er ændret. | Your week changed. |
| `list.stale.cta` | Opdatér sedlen | Update list |
| `list.empty.title` | Der er ikke noget at købe endnu. | Nothing to buy yet. |
| `list.empty.body` | Vælg nogle måltider, så bygger sedlen sig selv. | Pick some meals and your list builds itself. |
| `list.error.title` | Kunne ikke bygge din seddel. | Couldn't build your list. |
| `list.error.back` | Tilbage til din uge | Back to your week |
| `list.partial` | 1 måltid er ikke hentet til telefonen endnu. | 1 meal isn't on this phone yet. |
| `list.partial.cta` | Se hvilket | See which |
| `list.partial.remove` | Fjern fra ugen | Remove from week |
| `store.progress` | {n} af {t} | {n} of {t} |
| `store.doneGroup` | Færdige ({n}) | Done ({n}) |
| `store.finished` | Så er der købt ind. | That's the lot. |
| `imp.title` | Importér en opskrift | Import a recipe |
| `imp.prompt` | Indsæt et link fra en opskriftsside. | Paste a link from any recipe site. |
| `imp.cta` | Importér | Import |
| `imp.pasteInstead` | Eller indsæt opskriftens tekst | Or paste the recipe text instead |
| `imp.reading` | Læser {domain}… | Reading {domain}… |
| `imp.paste.placeholder` | Indsæt ingredienser og fremgangsmåde her. | Paste the ingredients and method here. |
| `imp.clipboardHint` | Indsat fra udklipsholderen | Pasted from the clipboard |
| `imp.stage1` | Fandt siden. Henter ingredienserne… | Found the page. Getting the ingredients… |
| `imp.slow` | Den her tager lidt tid — nogle sider er langsomme. | This one's taking a while — some sites are slow. |
| `imp.resumeDraft` | Fortsæt din import af {title}? | Continue importing {title}? |
| `imp.paste.title` | Indsæt opskriften | Paste the recipe |
| `imp.paste.titleLabel` | Titel | Title |
| `imp.paste.titlePlaceholder` | fx Mormors chili | e.g. Grandma's chili |
| `imp.paste.fromClipboard` | Indsæt fra udklipsholderen | Paste from clipboard |
| `rev.title` | Tjek importen | Check this import |
| `rev.flagged` | TJEK DISSE {n} | CHECK THESE {n} |
| `rev.ok` | SER FINE UD {n} | LOOKS GOOD {n} |
| `rev.fix` | Ret | Fix |
| `rev.skipLine` | Spring linjen over | Skip this line |
| `rev.noUnit` | ingen enhed | no unit |
| `rev.quickQty` | hurtig mængde | quick qty |
| `rev.save` | Gem og tilføj til denne uge | Save and add to this week |
| `rev.saveOnly` | Gem kun | Save only |
| `rev.willSkip` | {n} linjer springes over. | {n} lines will be skipped. |
| `rev.allOk` | ALT SER FINT UD {n} ✓ | ALL LOOKS GOOD {n} |
| `rev.reason.unknown` | Den kender vi ikke endnu | We don't know this one yet |
| `rev.reason.fuzzy` | Fik vi varen rigtigt? | Did we get the item right? |
| `rev.reason.qtyLost` | Fik vi mængden med? | Did we catch the amount? |
| `rev.reason.range` | Opskriften siger {low}–{high} — vi tog {low} | The recipe says {low}–{high} — we took {low} |
| `rev.reason.qtyGuessed` | Vi gættede på mængden | We guessed the amount |
| `rev.reason.qtyMissing` | Der står ingen mængde | No amount given |
| `rev.reason.unitDropped` | Er det {dropped_unit_word}? | Is it {dropped_unit_word}? |
| `rev.reason.coverage` | Vi har måske misset noget af linjen | We may have missed part of the line |
| `rev.servings.q` | Hvor mange er den til? | How many does it serve? |
| `rev.servings.why` | Det stod ikke på siden | It wasn't on the page |
| `rev.addTime` | Tilføj tid | Add time |
| `rev.suggest` | Mente du | Did you mean |
| `rev.addNew` | ＋ Tilføj "{name}" som ny vare | Add "{name}" as a new item |
| `rev.aisle` | Afdeling | Aisle |
| `rev.lineSkipped` | Linjen er sprunget over | Line skipped |
| `rev.capToast` | Opskriften er gemt. Syv er hele ugen — fjern én først. | Recipe saved. Seven is the whole week — remove one first. |
| `rev.addedToast` | {title} er tilføjet til ugen | {title} added to the week |
| `rev.savedToast` | Gemt i dine opskrifter | Saved to your recipes |
| `err.notRecipe.title` | Det ser ikke ud som en opskrift. | This doesn't look like a recipe. |
| `err.notRecipe.body` | Vi åbnede siden, men kunne ikke finde en ingrediensliste på den. | We opened the page but… |
| `err.notRecipe.bodyTitled` | Vi åbnede {title}, men kunne ikke finde en ingrediensliste på den. | We opened {title} but… |
| `err.notRecipe.other` | Prøv et andet link | Try a different link |
| `err.unreadable.title` | **Vi kunne ikke læse denne side.** | We couldn't read this page. |
| `err.unreadable.body` | Nogle sider lukker os ikke ind. Indsæt opskriftens tekst, så klarer vi resten. | Some sites don't let us in… |
| `err.unreadable.cta` | Indsæt opskriftens tekst | Paste the recipe text |
| `err.notUrl` | Det ser ikke ud som en webadresse. | That doesn't look like a web address. |
| `err.lostConnection` | Forbindelsen blev afbrudt. | Lost the connection. |
| `err.alreadyImported` | Den har du importeret før. | You've imported this one already. |
| `err.rateLimit.title` | Det var dagens importer. | That's today's imports. |
| `err.rateLimit.body` | Du kan importere igen i morgen. | You can import again tomorrow. |
| `err.rateLimit.signIn` | Log ind for at importere flere | Sign in to import more |
| `err.paused.title` | Import er sat på pause lige nu. | Import is paused right now. |
| `err.paused.body` | Prøv igen om lidt. Dine opskrifter og din uge virker som altid. | Try again soon. Your recipes and week work as usual. |
| `auth.prompt` | Gem jeres uge? Log ind, så er den der på enhver telefon. | Save your week? Sign in… |
| `auth.notNow` | Ikke nu | Not now |
| `auth.signIn` | Log ind | Sign in |
| `auth.body` | Vi sender en kode til din mail. | We'll email you a code. |
| `auth.sendCode` | Send kode | Send code |
| `auth.code.title` | Skriv koden fra mailen | Enter the code from the email |
| `auth.code.body` | Vi sendte den til {email}. | We sent it to {email}. |
| `auth.code.resend` | Send en ny kode | Send a new code |
| `auth.code.wrong` | Koden passer ikke. Prøv igen. | That code doesn't match. Try again. |
| `auth.code.expired` | Koden er udløbet. Vi har sendt en ny. | The code expired. We've sent a new one. |
| `auth.conflict.title` | Du har allerede en uge gemt. | You already have a saved week. |
| `auth.conflict.useSaved` | Brug den gemte ({n}) | Use the saved one ({n}) |
| `auth.conflict.keepPhone` | Behold denne telefons ({n}) | Keep this phone's ({n}) |
| `auth.signOut.title` | Log ud? | Sign out? |
| `auth.signOut.body` | Ugen og sedlen bliver slettet fra telefonen. De er gemt på din konto. | The week and list are removed from this phone. They're saved to your account. |
| `auth.delete.title` | Slet din konto? | Delete your account? |
| `auth.delete.body` | Dine importerede opskrifter og din gemte uge bliver slettet. Det kan ikke fortrydes. | Your imports and saved week are deleted. This can't be undone. |
| `auth.delete.confirm` | Slet konto | Delete account |

### Voice

- **`I` for the household, `du` for the person.** "Hvor mange laver **I** mad
  til?" but "**Du** kan ændre det senere." Getting this backwards makes it read
  like a corporate form.
- **No `venligst`, no `Beklager`.** Danish product copy that apologises sounds
  translated. Errors state what happened and what to do: "Vi kunne ikke læse
  denne side." then a button.
- **Imperatives, not `Ønsker du at…`.** `Vælg måltider`, `Byg sedlen`,
  `Prøv igen`.
- **`seddel`, not `liste`.** A Danish family writes an *indkøbsseddel*. `liste`
  is what software calls it.
- **Length discipline.** Danish compounds are long. `Se indkøbssedlen` is at the
  limit for a full-width CTA at XL type; anything longer gets cut, not wrapped.

### What this costs

| | |
|---|---|
| **Mobile + strings/design-system epics** | One strings file and no hardcoded copy. Every label specced to wrap/truncate — Danish runs ~15% longer. Numeric keypad must accept `,` as a decimal. |
| **Data-model epic** | Aisle / unit / cuisine / season constants (§9). `dl` in, `cup` out. `display_plural` authored, never derived. |
| **Content epic (curated recipes + ingredient table)** | 44 Danish family recipes, not British, and a Danish canonical ingredient table with aliases and plurals. |
| **Parser epic** | Comma decimals and Danish unit tokens; the LLM fallback is prompted in Danish and returns Danish ingredient names. |
| **Reversibility** | Changing locale again after the content epic writes the recipes is the expensive move — the 44 recipes and the whole canonical ingredient table are locale-bound. This is the last cheap moment. |
