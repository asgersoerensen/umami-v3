# Import & Review — screen design

| | |
|---|---|
| **Status** | Approved 12 Nov 2026 — copy approved; §10 open points decided. **Amended 13 Nov 2026 (spec rev 5):** `Gem` needs no account; screen F leaves the import flow. |
| **Source** | Ported from umami-v2 `docs/import-review-design.md` (prior art, ADR 0016) and adapted to the v3 decisions |
| **Supersedes** | spec §7 (the sketch). Build from this doc. |
| **Decisions applied** | [D3](../decisions/0003-deterministic-consolidation-and-local-ingredients.md) · [D4](../decisions/0004-week-lifecycle-and-soft-cap.md) · [D5](../decisions/0005-email-one-time-code-sign-in.md) · [D6 + R1](../decisions/0006-anonymous-first-sign-in-at-save.md) · [D10](../decisions/0010-imported-recipe-content-storage.md) · [D11](../decisions/0011-import-line-contract.md) · [D12](../decisions/0012-input-adapters-one-contract.md) · [D13](../decisions/0013-no-reflow-and-two-stage-import-skeleton.md) · [D15](../decisions/0015-import-review-design-ported.md) |

**Copy convention.** All user-facing copy is Danish and keyed for `da.ts` (spec
§12). Every string in this doc is approved and is listed in spec §12 under the
key shown here; spec §12 is the single source for the shipped wording. English
glosses are for the team only.

**Screen budget (from v2): unchanged.** One modal, four states (A–D), one
half-sheet (E). *Rev 5:* the inline sign-in step at `Gem` (F) is removed — `Gem`
saves on the phone without an account (ADR 0006 amended 13 Nov 2026). The D5
sign-in sheet is still reached from D-6 (`Log ind for at importere flere`).

---

## 0. The flow

```
   ┌ Picker: 🔗 Importér ┐       ┌ OS share sheet from a browser ┐
   └──────────┬──────────┘       └──────────────┬───────────────┘
              ▼                                 │  URL arrives; skip A
       ┌─ A · LINK ─┐                           │
       └─────┬──────┘◀── Prøv et andet link ┐   │
             ▼                              │   ▼
       ┌─ B · LÆSER ─────────────────────────┴──────────┐
       │  status fetched (~1s): title, image, domain     │
       │  status parsed:        ingredient rows          │
       └──────┬───────────────────────────┬─────────────┘
       parsed │                           │ failed / >25s / rate-limited
              ▼                           ▼
       ┌─ C · TJEK IMPORTEN ─┐      ┌─ D · KAN IKKE LÆSE DEN ─┐
       │  fix 2, not 14      │      │  paste text (primary)    │
       │      ┌──────────────┤      └───────────┬──────────────┘
       │      │ E · RET LINJE│                  ▼
       │      └──────────────┤          ┌─ INDSÆT TEKST ─┐──▶ B
       └──────┬──────────────┘          └────────────────┘
              ▼  Gem / Gem og tilføj
   Recipe saved on the phone (anonymous) or to the account (signed in)
   · (added to the week) · LIST tab, or OPSKRIFTER after Gem kun
```

Every arrow out of a failure leads somewhere. The one exception is the rate
limit (D-6), where the only honest next step is "later". Everywhere else, D
offers paste-text, and paste-text re-enters the same pipeline. It is just
another input adapter (D12), with the same `ParsedLine` contract out.

### 0a · Who owns what, when (R1)

| Phase | Identity | Stored where |
|---|---|---|
| A, B, C, E | Anonymous **device token**, which authorises *parse only* | The parse result is in the server's parse cache (by normalised URL, D10). The draft and all fixes are **on the phone**. |
| After `Gem`, anonymous | Device | The recipe, its lines and any new local ingredients are saved **on the phone only** (rev 5). Not backed up: deleting the app loses them. |
| After `Gem`, signed in | Account | Saved **to the account on the server** and kept on the phone. |
| First sign-in | Account | Anonymous imports and local ingredients upload with the week (ADR 0006). An import whose normalised URL the account already has is dropped; week entries point at the account's copy. |

If the user leaves C without saving (✕, app closed), the draft stays on the
phone: the most recent draft is kept for
**7 days** and survives app restarts. Reopening `Importér` while a draft exists
offers "Fortsæt din import af {title}?" (`imp.resumeDraft`) above screen A.

---

## 1. Entry points

### 1a · Paste a link — screen A

```
┌──────────────────────────────────────┐
│  ✕        Importér en opskrift       │  imp.title
│                                      │
│  Indsæt et link fra en opskriftsside.│  imp.prompt
│  ┌────────────────────────────────┐  │  Autofocus, URL keyboard.
│  │ https://www.valdemarsro.dk/…  ✕│  │  If the clipboard holds a URL:
│  └────────────────────────────────┘  │  prefill + select-all + caption,
│  Indsat fra udklipsholderen          │  imp.clipboardHint · a wrong prefill is one tap
│                                      │  to clear.
│  Eller indsæt opskriftens tekst ▸    │  imp.pasteInstead — always here
├──────────────────────────────────────┤
│              Importér ▸              │  imp.cta · bottom third
└──────────────────────────────────────┘
```

- **Clipboard prefill (from v2)** is the biggest time saver here. It is always
  labelled and always select-all'd, because it can be stale.
- `Importér` is disabled until the field parses as a URL. Invalid input shows
  inline (D-3) and never changes the screen.

### 1b · Native share sheet — no entry screen

Arriving from the Safari or Chrome share sheet → **skip A and land straight in
B**. Cold start: B renders over the launch surface, not after the tab bar
appears (from v2).

**Auth (R1, amended in rev 5): parse anonymously, save anonymously.** Share-into-app is often someone's
first interaction with Umami, so A–E run on the anonymous device token. The
token is issued silently at first launch, or at the first import if first
launch was offline. It authorises parsing only, at about 5 parses per day per
device, under a global spend cap. A signed-in account gets a higher daily limit
(config, initially 20 per day). Parses served from the server's parse cache
don't count against either limit. *Rev 5:* `Gem` never asks for sign-in; the
only sign-in entry inside import is D-6's `Log ind for at importere flere`.

---

## 2. Screen B · Læser — two stages, no fake progress (D13)

The client starts a job and polls its status every 1s (from v2). The job
resource returns a partial body at each status:

| `status` | Body carries | Source |
|---|---|---|
| `queued` | `domain` (known before fetch) | request |
| `fetched` | + `title`, `image_url`, `total_time_min?`, `servings_default?` | JSON-LD / `og:` tags (stage 1, ~1s) |
| `parsed` | + `lines[]` (D11 contract), `confidence_threshold` | JSON-LD fast path or LLM fallback (stage 2) |
| `failed` | `error_code`, `title?` if stage 1 got one | — |

Lines arrive all at once at `parsed`; there is **no per-field or per-line
streaming**. A pasted-text job goes `queued → parsed` with no image, and its
title comes from the paste screen.

```
    t=0                        t≈1s                      t≈2–8s
┌────────────────┐      ┌────────────────┐        ┌────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │      │ [   image   ]  │        │ [   image   ]  │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │      │ Kylling i karry│        │ Kylling i karry│
│ ▓▓▓▓▓▓▓▓ ▓▓▓   │      │ valdemarsro.dk │        │ valdemarsro.dk │
│ valdemarsro.dk │      │ ▓▓▓▓ · ▓▓▓▓▓▓  │        │ 25 min · til 4 │
│ ░░░░░░░░░░     │      │ ▓▓▓▓▓▓▓ ▓▓     │        │ ─────────────  │
│ ░░░░░░░░░░     │      │ ▓▓▓▓ ▓▓▓▓▓     │        │ (C renders in  │
│ ░░░░░░░░░░     │      │ ▓▓▓▓▓▓ ▓▓▓     │        │  place — same  │
│                │      │                │        │  layout)       │
│ Læser          │      │ Fandt siden.   │        │                │
│ valdemarsro.dk…│      │ Henter         │        │                │
│   Annullér     │      │ ingredienserne…│        │                │
└────────────────┘      └────────────────┘        └────────────────┘
  imp.reading            imp.stage1           parsed → C
```

- **B's layout is C's layout** (from v2). It has the same header, the same title
  block and the same row metrics. Skeleton rows have the exact height of review
  rows, so when `parsed` lands nothing moves. This is the import half of the D13
  no-reflow acceptance test.
- The stage-1 title is **provisional**. It is rendered at 70% opacity with no
  edit affordance until `parsed` (from v2).
- **Image (D10):** the client loads `image_url` straight from the source site
  (hotlinked) and caches it on the device. If there is no URL, or it fails to
  load, the slot renders `ImportTile` in the same footprint, so a broken image
  never changes the layout.
- **Status line:** one honest sentence per stage. It never shows a percentage and
  never names the extraction path.
  - `queued`: `imp.reading` "Læser {domain}…"
  - `fetched`: "Fandt siden. Henter ingredienserne…" (`imp.stage1`)
- `Annullér` (`common.cancel`) is there from t=0. Cancelling abandons the job
  client-side, but the server may finish it and cache the result.
- **Timing (from v2):**
  - **12s** with no `parsed`: the status line softens to "Den her tager lidt tid —
    nogle sider er langsomme." (`imp.slow`), and a secondary
    `Indsæt opskriftens tekst` (`err.unreadable.cta`) button appears below
    `Annullér`. The parse keeps running.
  - **25s** with no `parsed`: go to **D-2**. `Prøv igen` there polls the same job
    (same `Idempotency-Key`), so a parse that finished late is picked up rather
    than re-run.

---

## 3. Screen C · Tjek importen

**The core idea (from v2): don't ask anyone to audit 14 lines. Ask them to fix
2.** Confidence is computed by the parser, and the weakest part wins (D11), so
the flagged set is small and genuinely suspect.

```
┌──────────────────────────────────────┐
│  ✕          Tjek importen            │  rev.title
│  ┌────────────────────────────────┐  │
│  │ [ image / ImportTile ]         │  │
│  │ Kylling i karry             ✎  │  │  tap = edit title
│  │ 25 min ✎ · til 4 personer ✎    │  │  meta chips tap to edit
│  │ valdemarsro.dk ↗               │  │  attribution, live from stage 1
│  └────────────────────────────────┘  │
│                                      │
│  TJEK DISSE 3                        │  rev.flagged · amber, counts down
│  ┌────────────────────────────────┐  │
│  │ ● 1   bundt  forårsløg       › │  │
│  │   Vi gættede på mængden        │  │  ← reason, one line (§3a)
│  │   "et bundt forårsløg"         │  │  ← raw_text, always
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ ● 1   spsk   gochujang       › │  │
│  │   Den kender vi ikke endnu     │  │
│  │   "1 spsk gochujang"           │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ ● 2    —     spinat          › │  │
│  │   Er det håndfulde?            │  │  names dropped_unit_word
│  │   "2 håndfulde spinat"         │  │
│  └────────────────────────────────┘  │
│                                      │
│  SER FINE UD 11                 ⌄    │  rev.ok · collapsed; rows editable
├──────────────────────────────────────┤
│     Gem og tilføj til denne uge      │  rev.save · never disabled
│     2 linjer springes over.          │  rev.willSkip (only if flags remain)
│              Gem kun                 │  rev.saveOnly
└──────────────────────────────────────┘
```

### 3a · Why a line is flagged, in the user's words

The line contract (D11, adopted verbatim from v2) carries
`confidence_parts {quantity, unit, ingredient, coverage}`, `ingredient_match`
(`exact|alias|fuzzy|unresolved`) and `dropped_unit_word`. A line is flagged when
`confidence < confidence_threshold`. The threshold comes from the payload, and
the app never hardcodes or displays it. The reason is picked from the weakest
part. On a tie, the order is **ingredient > quantity > unit > coverage**. When
the weakest part is `quantity` and the line has `is_range: true`, the range
reason is shown instead of the generic guess reason; `{low}` = `quantity`,
`{high}` = `quantity_high`, both formatted with a Danish comma.

| Weakest part / signal | Reason line | Key | Fix sheet focuses |
|---|---|---|---|
| `ingredient_match: unresolved` | "Den kender vi ikke endnu" | `rev.reason.unknown` | item, suggestions shown |
| `ingredient_match: fuzzy` | "Fik vi varen rigtigt?" | `rev.reason.fuzzy` | item |
| `quantity` 0.3 (a digit was lost) | "Fik vi mængden med?" | `rev.reason.qtyLost` | quantity |
| `is_range: true` (we took the low end) | "Opskriften siger {low}–{high} — vi tog {low}" | `rev.reason.range` | quantity |
| `quantity` 0.7 (inferred — we supplied the number) | "Vi gættede på mængden" | `rev.reason.qtyGuessed` | quantity |
| `quantity` 0.6 (no amount in the source) | "Der står ingen mængde" | `rev.reason.qtyMissing` | quantity |
| `unit` 0.3 with `dropped_unit_word` | "Er det {dropped_unit_word}?" | `rev.reason.unitDropped` | unit |
| `coverage` low | "Vi har måske misset noget af linjen" | `rev.reason.coverage` | item |

Copy rules (from v2, applied with §12's voice):
- **vi** owns the mistake, never du.
- No numbers, percentages or "lav sikkerhed".
- Never "fejl" for a line: a line is a question, not a fault.
- No `venligst`, no `Beklager`.

### 3b · Missing required fields become flagged rows (from v2)

`servings_default` is required, and stage 1 can leave it null. It joins the
**same queue** at the top of `TJEK DISSE`:

```
│  ┌────────────────────────────────┐  │
│  │ ● Hvor mange er den til?    › │  │  rev.servings.q
│  │   Det stod ikke på siden       │  │  rev.servings.why
│  └────────────────────────────────┘  │  Tap → stepper, defaults to
                                          household servings.
```

A missing `total_time_min` shows as a chip, `Tilføj tid` (`rev.addTime`), and doesn't
block. A recipe can be shown without a time, but it can't be scaled without
servings. While time is null, `time_band` is null and the recipe matches no time
chip (D14).

### 3c · Save rules

- `Gem og tilføj til denne uge` is **never disabled** (from v2).
- **Unfixed lines are dropped, not saved broken.**
  - The subtitle `rev.willSkip` states the consequence.
  - A line is "fixed" once it has a canonical **or** local ingredient (D3). Lines
    only ever exist with an ingredient; there are no free-text-only lines.
- **The one true block is servings.** If servings is still unanswered, tapping
  either save button scrolls to that row and focuses the stepper, with no error
  shown.
- **Not signed in** → the save completes on the phone (§3d). No sign-in step.
- **Open flags don't block** (decided in rev 5): lines with an ingredient but an
  open flag save with the parser's value; lines with no ingredient are dropped
  (`rev.willSkip`).
- **The soft cap of 7 (D4).** If the week already has 7 meals,
  `Gem og tilføj til denne uge` behaves as `Gem kun` and shows the toast
  "Opskriften er gemt. Syv er hele ugen — fjern én først."
  (`rev.capToast`), which extends `pick.maxToast`.
- **After `Gem og tilføj`:**
  - The modal dismisses to the **List** tab, with the toast
    "{title} er tilføjet til ugen" (`rev.addedToast`).
  - The list is built on the phone (D2). On arrival:
    - **no list yet, or a list with nothing bought** → the list is
      **rebuilt automatically**, so the new recipe's items are visible at once;
    - **a list with at least one item bought** → the list is marked **stale**
      (V9) and shows `list.stale.title` / `list.stale.cta`. We never recompute
      under someone mid-shop (ADR 0018, V9 amendment).
- **After `Gem kun`:** the modal dismisses to the **Opskrifter** tab filtered to
  `Kun mine importerede` (rev 5), with the toast "Gemt i dine opskrifter"
  (`rev.savedToast`). When the import came from
  the share sheet (no starting screen), it lands on the new recipe's **Recipe
  Sheet** (default; the UX epic may revisit).
- **On save when signed in (or at the first-sign-in upload), the server, for the
  account:**
  - creates the recipe record (facts only, D10);
  - creates any new local ingredients, or reuses the account's existing local
    ingredient on an **exact normalised-name** match;
  - queues new local ingredients for curation (D3).

### 3d · Saving without an account (rev 5; was Screen F)

*Rev 5 removes Screen F (sign-in at `Gem`).* `Gem` always completes at once.

- **Anonymous:** the recipe, its lines and any new local ingredients are written
  to the phone's store with client-generated ids. They upload at first sign-in
  (§0a, ADR 0006), each with an `Idempotency-Key`.
- **Signed in:** saved to the account as before (§8 contract 3) and kept on the
  phone.
- **Duplicate found at save:** if the phone (anonymous) or the account (signed
  in) already has a recipe from this normalised URL, the draft's fixes are
  discarded, the toast `err.alreadyImported` shows, and the existing recipe's
  Recipe Sheet opens. If `Gem og tilføj` was pressed, the existing recipe is
  added to the week (subject to the cap of 7).
- **Duplicate found at first-sign-in upload:** the account's copy wins; the
  phone's copy is dropped and its week entry re-pointed. No question asked.

---

## 4. Screen E · Ret linjen — the two-second tap

The half-sheet opens **already focused on the field we know is wrong** (§3a). The
common case is: tap the row → tap a chip → done.

```
┌──────────────────────────────────────┐
│ ─────                                │
│  "1 spsk gochujang"                  │  raw_text, always at the top
│  ┌─────┐ ┌─────────┐ ┌────────────┐  │
│  │  1  │ │ spsk  ⌄ │ │ gochujang  │  │  qty · unit · item; focused is ringed
│  └─────┘ └─────────┘ └────────────┘  │
│  Mente du                            │  rev.suggest · suggested_ingredients (≤5)
│  ( chilipasta ) ( misopasta )        │  tap = accept and close
│  ＋ Tilføj "gochujang" som ny vare   │  rev.addNew — always last
│     Afdeling: ( KOLONIAL ✓ ) ( … )   │  rev.aisle; aisle chips appear
│                                      │  only after "Tilføj" is tapped
├──────────────────────────────────────┤
│  Spring linjen over       ✓ Færdig   │  rev.skipLine · common.done
└──────────────────────────────────────┘
```

**Field behaviour**

- **Quantity:**
  - The numeric keypad opens with the value selected, and quick pills
    `½ 1 2 3` (`rev.quickQty`) sit above it.
  - It accepts `1/2`, `,5`, `.5`, `1 1/2` and `1½`.
  - It displays with a comma; the stored value is a decimal (spec §7c).
- **Unit:**
  - A picker over the closed Danish unit set.
  - `ingen enhed` (`rev.noUnit`) comes first, then the units used in this
    recipe, then the rest.
  - Never free text.
- **Item:**
  - Autocomplete over the canonical table plus the account's own local
    ingredients (when signed in).
  - It opens **pre-populated** from `suggested_ingredients`, which carry
    `{id, name, display_plural, aisle}`, so there are no lookups before the
    chips show.
- **`＋ Tilføj "{name}" som ny vare`** creates a **draft local ingredient**
  (D3):
  - The name is normalised (lower-cased, whitespace collapsed, Danish letters
    kept, folded only for matching).
  - The aisle is pre-selected from the parser's proposal, or `andet`, and one
    tap on the aisle chip row changes it.
  - `is_staple=false`.
  - It becomes account-owned at save (§3c). The user never sees the word
    "lokal".
- **`Spring linjen over`** sits beside Done, not in a menu. Removing a line shows
  a 5s undo toast on C: "Linjen er sprunget over" (`rev.lineSkipped`) + `Fortryd` (`common.undo`).

**On `Færdig`:**
- The row animates from `TJEK DISSE` into `SER FINE UD`, the counter decrements,
  and a light haptic tick fires.
- When the last flag clears, the header becomes `ALT SER FINT UD {n} ✓`
  (`rev.allOk`, green) and the save subtitle disappears.
- A corrected line is sent with `confidence: 1.0` and `confidence_parts: null`
  (D11).

Accepting a suggestion chip closes the sheet immediately. To undo, re-tap the
row.

---

## 5. Screen D · Failures, mapped to `error_code`

The app switches on `error_code`, and **anything unrecognised falls back to
D-2** (from v2). An unknown code must never render a blank state.

| `error_code` | Screen | Primary action |
|---|---|---|
| `no_recipe_found` | D-1 | Indsæt opskriftens tekst |
| `fetch_failed`, `blocked`, `paywalled`, `timeout`, *unknown*, client 25s | D-2 | Indsæt opskriftens tekst |
| `not_a_url` (client-side) | D-3 inline | — |
| offline (client-side) | D-4 | Prøv igen |
| duplicate (not an error) | D-5 toast | — |
| `rate_limited` (device's daily parses used) | D-6 | Luk |
| `import_paused` (global spend cap) | D-6b | Luk |

**D-1 · Not a recipe page**
- `err.notRecipe.title` / `err.notRecipe.body`.
- Primary `err.unreadable.cta`; secondary `err.notRecipe.other`.
- If stage 1 got a title, the body becomes "Vi åbnede **{title}**, men kunne ikke
  finde en ingrediensliste på den." (`err.notRecipe.bodyTitled`).
  Naming the page is how someone realises they shared the wrong tab.

**D-2 · We couldn't read this page**
- `err.unreadable.title` / `err.unreadable.body`.
- Primary `err.unreadable.cta`; then `common.retry` (same job and
  `Idempotency-Key`) and `err.notRecipe.other`.

**D-3 · Not a URL** — inline `err.notUrl` under the field; `Importér` stays
disabled.

**D-4 · Offline**
- `🔗 Importér` is dimmed in the Picker, and tapping it shows the toast
  `pick.importOffline`.
- If the connection drops mid-parse: `err.lostConnection` + `common.retry` +
  `err.unreadable.cta`. Pasted or typed content is kept.

**D-5 · Already imported**
- Signed in: if the account already has a recipe from this normalised URL,
  there's no parse. Go straight to its Recipe Sheet with the toast
  `err.alreadyImported`.
- Anonymous: there is no parse either if the phone already has a recipe from
  this normalised URL; otherwise duplicates are caught at `Gem` (§3d).

**D-6 · Daily limit reached** (`rate_limited`)

```
        ⏳
   Det var dagens importer.               err.rateLimit.title
   Du kan importere igen i morgen.        err.rateLimit.body
   [ Log ind for at importere flere ]     err.rateLimit.signIn (anonymous only)
   [ Luk ]                                common.close
```

Paste-text is **not** offered, because it is also a parse and would hit the same
limit. Anything already typed is kept.
- **Anonymous** (device limit, ~5/day): primary `Log ind for at importere
  flere` opens the D5 sign-in sheet with `reason: 'import'`; on success the parse is retried under
  the account's higher limit. Secondary `Luk`.
- **Signed in** (account limit, initially 20/day): only `Luk`.

**D-6b · Import is paused** (`import_paused`, global spend cap hit)
- "Import er sat på pause lige nu." (`err.paused.title`)
- "Prøv igen om lidt. Dine opskrifter og din uge virker som altid."
  (`err.paused.body`)
- Then `Luk`.

### Paste-text mode (D12 adapter)

```
┌──────────────────────────────────────┐
│  ✕          Indsæt opskriften        │  imp.paste.title
│  Titel  ┌──────────────────────────┐ │  imp.paste.titleLabel
│         │ fx Mormors chili         │ │  imp.paste.titlePlaceholder
│         └──────────────────────────┘ │
│  ┌────────────────────────────────┐  │  imp.paste.placeholder
│  │ Indsæt ingredienser og         │  │  Multi-line, grows. Clipboard
│  │ fremgangsmåde her.             │  │  offered as a button, not
│  └────────────────────────────────┘  │  auto-filled (from v2):
│  [ Indsæt fra udklipsholderen ]      │  imp.paste.fromClipboard
├──────────────────────────────────────┤
│              Importér ▸              │  imp.cta
└──────────────────────────────────────┘
```

- The ingredients alone are enough, and nothing checks that a method is present.
- The pasted text is kept as `raw_source_text` on the user's own private recipe
  (for re-parse and debugging). It is never shown to anyone else (from v2).
- After the imported recipe is saved, its sheet shows **no** method, because v1
  doesn't store method text for imports (D10), not even the user's own pasted
  text (decided, §10 point 6). Its sheet shows no method row at all, since
  there is no source to link to.
- Photo/OCR and video are future adapters with the same contract out. They are
  not in v1 (spec §10).

---

## 6. Attribution and images (D10)

Imports store **facts only**: title, time, servings, lines, `source_url`,
`domain`, and `image_url`. There is no method text and no image bytes. That makes
the source link the only way to actually cook an imported recipe, so attribution
matters more, not less.

Attribution appears in exactly three places:

1. **Screens B and C:** `{domain} ↗` under the title, from stage 1.
2. **Recipe Sheet:** for imports only, the `Fremgangsmåde ⌄` accordion is
   replaced by a full-width, tappable `MethodLinkBlock` (adapted from v2's
   `AttributionBlock`):

   ```
   │  ┌────────────────────────────────┐  │
   │  │ Fremgangsmåde · Se den på      │  │  recipe.methodLink
   │  │ valdemarsro.dk ↗               │  │  "Fremgangsmåde · Se den på {domain} ↗"
   │  └────────────────────────────────┘  │  opens source_url in the in-app browser
   ```

   It's not an empty accordion and not a small grey link: someone at the hob
   needs the method in one obvious tap. Imports in v1 are for planning and
   shopping, not cooking along (accepted, from v2).
3. **Grocery list:** nothing.

Curated recipes show their method inline and have no `MethodLinkBlock`. The
recipe's `source` tells the app which one to render.

**Images:**
- `image_url` is the source's own image URL (from JSON-LD `image` or
  `og:image`). The phone loads it straight from the source site and caches it on
  the device.
- If it is missing, fails to load, or is gone later, the phone renders
  `ImportTile`: the title's first letter on a flat colour keyed off `cuisine`,
  with the domain underneath.
- Never a broken-image frame, and never a stock photo (from v2).
- Curated recipes always have a bundled `hero_image`, which is required for
  curated recipes only.

---

## 7. Components

New components and their props, adapted from v2:

| Component | Props | Notes |
|---|---|---|
| `UrlEntryField` | `value, onChange, clipboardHint, error` | Clipboard prefill + caption + clear |
| `ImportProgressHeader` | `title?, domain, imageUrl?, cuisine?, status, provisional` | Renders the headers for **both** B and C. One component is what makes the transition seamless. |
| `RemoteRecipeImage` | `uri?, fallback: ReactNode, aspect` | Hotlink + on-device cache. Renders `fallback` in the same footprint on null or error. |
| `ParseStatusLine` | `status, elapsedMs, onPasteInstead` | Owns the stage copy and the 12s softening |
| `FlagGroupHeader` | `count, tone: 'amber' \| 'green'` | `TJEK DISSE 3` / `ALT SER FINT UD 14 ✓` |
| `IngredientReviewRow` | `line, flagged, reason?, onPress` | Row + reason + `raw_text`. Fixed height per state (64 / 72pt). |
| `MetaChip` | `label, value?, required, onPress` | `25 min ✎`, `Tilføj tid`, `til 4 personer ✎` |
| `FixLineSheet` | `line, suggestions, focusField, onDone, onSkip` | Screen E |
| `QuantityPills` | `values, onSelect` | `½ 1 2 3` |
| `UnitPicker` | `value, recentUnits, onSelect` | Closed set; `ingen enhed` first |
| `IngredientAutocomplete` | `query, suggestions, onSelect, onCreate(name)` | Opens pre-populated |
| `AisleChipRow` | `value, onSelect` | Used only for a new local ingredient; walking order per §12 |
| `SignInSheet` | `reason: 'import' \| 'week', onSignedIn, onCancel` | The D5 sheet. Email → 6-digit code. Opened from D-6 (`reason: 'import'`), the D6 prompt and `⚙ → Log ind`; not from `Gem` (rev 5). |
| `ImportErrorState` | `errorCode, scrapedTitle?, actions[]` | D-1, D-2, D-4, D-6, D-6b |
| `ImportTile` | `title, cuisine, domain` | Image fallback |
| `MethodLinkBlock` | `domain, sourceUrl` | Recipe Sheet, imports only (replaces v2's `AttributionBlock`) |

Reused from the design system: `Skeleton`, `Toast`, `PrimaryCta`, `SheetHeader`.

**Metrics (from v2):**
- Review rows are 64pt, and 72pt when flagged. Skeleton rows use the same
  heights.
- Fix-sheet fields are 48pt. Targets are at least 44pt, and primary actions sit
  in the bottom third.
- Body text is 17pt; `raw_text` is 15pt at 60% opacity.
- Amber and green are the only accents in this flow. Amber means a question, not
  a warning: it appears only as an 8pt dot and a header, never as a filled row.
- Every label is specced to wrap or truncate at XL text size (Danish runs about
  15% longer).

---

## 8. Contract this design depends on

These are the shapes the design needs from the backend. They are owned by the
parser and backend epics.

1. **Job resource:** `POST /imports/` takes `{url}` or `{text, title}`, an
   `Idempotency-Key` header, and the device token or account token. It returns
   `{id, status}`. `GET /imports/{id}` returns the partial body per status (§2).
2. **The line contract (D11), verbatim from v2:**
   - `position`, `raw_text`, `quantity`, `quantity_high` (range high end or
     null), `is_range`, `unit` (closed set or null), `ingredient`,
     `preparation`, `is_optional`;
   - `confidence`, `confidence_parts {quantity, unit, ingredient, coverage}`,
     `ingredient_match`;
   - `suggested_ingredients[≤5] {id, name, display_plural, aisle}`,
     `dropped_unit_word`;
   - for unresolved lines, the parser's proposed aisle.
   - Plus `confidence_threshold` at the top level.
3. **Save:** `POST /recipes/from-import/{id}` (account token required) with the
   reviewed draft — at `Gem` when signed in, or from the first-sign-in upload
   for imports saved anonymously (rev 5). The body is self-contained, so the
   upload doesn't depend on the import job still existing. The draft carries corrected lines, skipped positions and draft
   local ingredients `{name, aisle}`. The server dedupes local ingredients by
   normalised name.
4. **Device token:** issued at first launch (or first import). Parse-only scope,
   rate-limited per device (~5/day), under a global spend cap. Account tokens
   get a higher per-account limit (initially 20/day). Parse-cache hits count
   against neither. Returns `rate_limited` and `import_paused` error codes.
5. **The `error_code` enum** from §5. Unknown codes → D-2.
6. **Share extension:** opens at B with the URL, not at A.

---

## 9. Done when

- **Fixing a wrong line is obviously trivial.**
  - Flagged rows are hoisted to the top with a plain-Danish reason.
  - The sheet opens focused on the wrong field, and the fix is a chip tap.
  - Worst case is one keypad entry; the typical case is three taps and no
    keyboard.
- **A failed import never leaves someone stuck.**
  - Every failure's primary action is paste-text, except the rate limit, which
    says exactly when it clears.
  - Slow parses soften at 12s instead of dying.
  - Unknown codes fall back to D-2.
- **Nothing reflows between B and C.** This is tested by comparing layout
  snapshots across `fetched` → `parsed` (D13).
- **Saving never needs a network round-trip for identity.** Anonymous `Gem`
  writes to the phone; nothing is lost if sign-in never happens on that phone
  (rev 5).

---

## 10. Decided points (12 Nov 2026)

These were open when the doc was ported; all are now decided and reflected in
the body above.

1. **Rebuild after `Gem og tilføj`** — rebuild automatically on arrival when no
   item is bought yet; otherwise show the stale banner (§3c; ADR 0018 V9
   amendment).
2. **Duplicate found after sign-in** — discard the draft, show
   `err.alreadyImported`, open the existing recipe; add it to the week if
   `Gem og tilføj` was pressed (§3d).
3. **Draft lifetime** — the most recent draft is kept for 7 days and survives
   restarts; `Importér` offers "Fortsæt din import af {title}?" (§0a; ADR 0006).
4. **Signed-in limit** — accounts get a higher daily limit (config, initially
   20/day). D-6 offers `Log ind for at importere flere` to anonymous users only
   (§5; ADR 0006).
5. **Parse-cache hits** — don't count against any limit (ADR 0006).
6. **Pasted method text** — pasted imports display no method in v1 (§5 paste
   mode).
7. **Range vs guess** — the line contract gains `is_range` and `quantity_high`;
   range lines still flag, with the reason "Opskriften siger {low}–{high} — vi
   tog {low}" (§3a; ADR 0011).
8. **Skipped unresolved lines** — still dropped (v2 behaviour) until the parser
   spike reports wrong-match numbers; revisit then.
9. **Relabel the primary button when the week is full** — deferred to the UX
   epic; the toast (§3c) stands meanwhile.
10. **Landing after `Gem kun` from the share sheet** — the new recipe's Recipe
    Sheet by default (§3c); the UX epic may revisit.
