# Umami v1 — Architecture overview

- **Status:** Approved · 12 Nov 2026 (A1–A11)
- **Inputs:** `docs/product/spec.md` (rev 4), ADRs 0001–0018 in `docs/decisions/`,
  `docs/product/import-review-design.md`
- **Scope:** the decisions that are expensive to change later. Library-level
  choices inside one epic are left to that epic unless they leak across a
  boundary.

## Choices made in this document (approved 12 Nov 2026)

Everything else here restates an accepted ADR. These are new:

| # | Choice | Why | Section |
|---|---|---|---|
| A1 | **One repo, three parts:** `apps/mobile` (Expo), `packages/core` (pure TS domain logic), `server/` (Django). `fixtures/` shared by both test suites. | Shared golden fixtures need one source of truth. | §2 |
| A2 | **On-device store = SQLite** (`expo-sqlite`) behind a repository layer. Not AsyncStorage/MMKV. | Relational data (recipes ↔ lines ↔ ingredients), transactions for the list rebuild, and an outbox. | §3.2 |
| A3 | **Server list-builder parity is *not* built in v1.** Python implements only the shared *primitives* (units, quantities, normalisation, `time_band`) and runs the same fixtures. | Nothing on the server needs a list in v1. Fixtures keep the door open. | §5 |
| A4 | **Curated content ships in the app and updates through delta sync**; curated images are served from a **Render Static Site** (CDN) with hashed filenames, and the 44 launch images are bundled. | No object storage to run; the picker never waits for the network. | §4 |
| A5 | **Sync = per-record last-write-wins on server-issued versions**, with a client outbox. Week entries, item states and extra items are separate records; no week-level document merge. | Matches v2's replay-safety rules; two phones on one account converge. | §6 |
| A6 | **Auth tokens are opaque, hashed at rest, 90-day sliding.** Device tokens are a separate token type, scope = parse only. | Revocable on sign-out and deletion; no JWT key management. | §8 |
| A7 | **Email provider = Brevo** (EU, France). Postmark has no EU data region. | ADR 0009 requires an EU processor. Amends ADR 0009. | §11 |
| A8 | **Periodic jobs run as Procrastinate periodic tasks** in the worker; no Render cron service. | One process type fewer. | §11 |
| A9 | **Two Render environments**, `staging` and `production`, from one `render.yaml` blueprint. | Store review and the family usability test need a stable non-prod. | §11 |
| A10 | **Fuzzy ingredient matching uses Postgres `pg_trgm`** on normalised names and aliases, server-side at import only. | Deterministic, testable, no extra service. | §7.4 |
| A11 | **GitHub + GitHub Actions** for source and CI; staging deploys from main, production by manual promotion. *(Decided by you, 12 Nov.)* | — | §11 |

---

## 1. Shape of the system

```
                    ┌─────────────────────────────────────────────────┐
                    │  Phone (Expo app, iOS first)                     │
                    │                                                  │
                    │  UI (screens §1–7) ── state ── repositories       │
                    │                         │                        │
                    │        packages/core    │      SQLite            │
                    │   (list builder, units, │  recipes · ingredients │
                    │    time_band, normalise)│  week · item_states    │
                    │                         │  outbox · drafts       │
                    │  bundled: content.json + 44 hero images          │
                    └───────────┬──────────────────────┬──────────────┘
                     HTTPS /api/v1 (only for: content delta, sync when
                     signed in, import, sign-in, counts)│
                                │                      │ image GETs
          ┌─────────────────────▼───────────┐   ┌──────▼──────────────────┐
          │ Render · Frankfurt               │   │ Recipe sites (hotlink)  │
          │                                  │   │ Render Static Site (CDN)│
          │  web: Django + DRF (gunicorn)    │   │  curated images         │
          │  worker: Procrastinate           │   └─────────────────────────┘
          │      import parse · purge ·      │
          │      code email · cleanup        │──▶ Anthropic API (page text only)
          │  Postgres (direct conn, PITR)    │──▶ Recipe sites (fetch)
          │                                  │──▶ Brevo (code emails, EU)
          └──────────────────────────────────┘──▶ Sentry (EU)
```

**Principles, in priority order**

1. **The loop never needs a network.** Pick → plan → list → in-store runs
   entirely on the phone (ADR 0002). The server is for import, accounts, sync and
   content updates.
2. **The list is deterministic.** Same inputs, same list, on any device, offline.
   No LLM, no clock, no randomness at list time (ADR 0003).
3. **The LLM is a suggestion engine at import time**, confirmed by a human, and
   never sees personal data (ADR 0009, 0011).
4. **Every write converges when replayed** (v2 replay-safety rules, ADR 0016).

---

## 2. Repository layout (A1)

```
apps/mobile/          Expo app (expo-router, TypeScript)
  src/strings/da.ts   the only place user-facing copy lives (spec §12)
  assets/content/     generated: content.json + images/{recipe_id}.webp
packages/core/        pure TS, no React, no I/O
  units.ts            closed unit set, families, conversions (dl↔ml↔l, g↔kg)
  quantity.ts         Danish parse/format at the edges (comma, ½ ¼ ¾)
  normalise.ts        normalise_name (lower, trim, æøå→ae/oe/aa, size words)
  timeBand.ts         ≤20 / 21–30 / 31+
  buildList.ts        the list builder (§5)
server/               Django project
  umami/accounts      email codes, sessions, device tokens, deletion
  umami/content       recipes, ingredients, aliases, curation queue, admin CMS
  umami/imports       pipeline, adapters, parse cache, rate limits
  umami/sync          week, item states, extra items, user recipes
  umami/telemetry     anonymous counts
  umami/core          units/quantity/normalise/time_band (Python mirror)
fixtures/             golden JSON shared by both test suites
  units/ quantity/ normalise/ time_band/ build_list/ import_lines/
render.yaml
```

- `packages/core` is consumed by the app directly (workspace package) and is
  the **only** implementation of the list builder.
- `server/umami/core` mirrors the primitives in Python. **Both** test suites run
  every file in `fixtures/{units,quantity,normalise,time_band}`; a fixture that
  passes in one language and fails in the other fails CI.
- The typed API client for the app is generated from the server's OpenAPI
  schema (`drf-spectacular`), checked in, and regenerated in CI to detect drift.

---

## 3. Client (Expo)

### 3.1 Platform (ADR 0008)

- Expo SDK, **development builds** (not Expo Go) — required for the share
  extension (iOS) / intent filter (Android) for share-sheet import.
- `expo-router` for navigation: two tabs (Plan, List), Picker as a full-screen
  modal, Recipe Sheet as a sheet, Import as a modal, In-Store as a takeover.
- `expo-image` for every image: disk caching for hotlinked import images,
  `thumbhash` placeholders for curated images, a fixed-size `ImportTile`
  fallback (ADR 0010).
- `expo-keep-awake` in In-Store mode; `expo-haptics` for the two haptics.
- Release iOS first; CI builds Android on every main build (EAS Build).
- OTA: EAS Update for JS and bundled-asset fixes. Content does **not** depend on
  EAS Update (§4).

### 3.2 On-device data (A2)

SQLite via `expo-sqlite`, accessed only through repository modules (a typed
query layer such as Drizzle is the mobile epic's call). UI state reads through
the repositories; nothing in a component touches SQL.

| Table | Holds | Source |
|---|---|---|
| `recipe`, `ingredient_line` | curated + the user's imports | bundle, delta sync, user sync |
| `ingredient` (+ `alias`) | canonical table | bundle, delta sync |
| `local_ingredient` | the account's local ingredients | user sync (signed in only) |
| `household` | `household_servings` | local; synced when signed in |
| `week_entry` | `{id, recipe_id, servings_override}` | local; synced |
| `item_state` | `{item_key, state, changed_at}` | local; synced |
| `extra_item` | hand-added items | local; synced |
| `list_snapshot` | the last built list + `built_from_hash` | local only, derived |
| `import_draft` | the single latest unsaved import (7 days) | local only |
| `outbox` | pending writes | local only |
| `meta` | content cursor, sync cursor, tokens, `content_version` | local only |

- **IDs:** curated recipes and canonical ingredients use v2's derived uuid5 ids.
  Everything created on the phone uses a client-generated UUIDv7.
- **Stale detection (V9):** `list_snapshot.built_from_hash` = a hash of the
  list-affecting inputs (entry recipe ids, servings overrides, household
  servings, content versions of those recipes). The banner shows when the
  current hash differs. No timestamps compared.
- Tokens are kept in `expo-secure-store`, not SQLite.

### 3.3 Screens are thin

Screens call repositories and `packages/core`. The no-reflow acceptance test
(ADR 0013) is owned by the Picker epic: fixed card height, stable keys,
memoised cards, the tray subscribes separately from the list.

---

## 4. Content: curated recipes and the canonical table (A4)

**Source of truth:** Postgres, edited in Django admin. Seeded from v2's
`slate.yaml` (44 recipes, uuid5 ids, namespace
`6f1e8a52-3c47-5a9b-9d21-0e7c4b8f1a30`) and v2's canonical ingredient seed,
both reviewed by the content epic (ADR 0016).

**Into the app:**
1. `manage.py export_bundle` writes `content.json` (recipes, lines, canonical
   ingredients, aliases, `content_version`) through the **same serializers as
   the API**, plus `images/{recipe_id}.webp` (1080 px, ≤80 KB, with thumbhash).
   CI copies the output into `apps/mobile/assets/content/` at build time.
2. On first launch the app loads `content.json` into SQLite in one transaction.
3. **Delta sync** (background, when online): `GET /api/v1/content?since=<cursor>`
   returns changed recipes, ingredients and aliases ordered by `updated_at`,
   with tombstones for deleted/unpublished rows (v2 rules: merge on id, server
   wins, cursor = max `updated_at` seen, never the client clock).
4. New curated images after launch are fetched from the **Render Static Site**
   (immutable hashed URLs; CDN-cached). The 44 launch images are bundled, so
   the first-run picker needs no network.

**Canonical ingredient table** (ADR 0003, spec §9):

| Field | Notes |
|---|---|
| `id` | uuid5 for seeded rows |
| `name` | singular Danish; unique on `normalise(name)` |
| `display_plural`, `pluralises` | authored, never derived |
| `aisle` | 9-value enum in walking order |
| `is_staple` | drives the skipped-by-default state |
| `default_unit` | display preference after merging (V3) |
| aliases | **separate table, unique index on normalised alias** (v2), so two ingredients can never claim the same alias and resolution stays deterministic |

Target **300–400 rows** before launch, covering every ingredient in the 44
recipes plus the most common ingredients on the five named sites (measured by
the parser spike).

**Curation queue.** Every `local_ingredient` appears in an admin queue with its
usage count. An editor either:
- **promotes** it → a new canonical row (+ alias); or
- **maps** it → an existing canonical row (+ alias).

Either way the owning user's lines are rewritten to the canonical id
server-side, and the change reaches the phone through user sync (§6). Their
list merges correctly on the next rebuild.

---

## 5. The grocery list (ADR 0002, 0003, 0018)

**Built on the phone, by one pure function in `packages/core`:**

```
buildList(input: {
  entries, recipes, lines, ingredients, localIngredients,
  householdServings, priorStates, extraItems
}) → { rows: ListRow[], missingRecipeIds: string[] }
```

Steps:

1. **Expand.** For each entry, take its recipe's lines. Entries whose recipe
   isn't on the phone go to `missingRecipeIds` → **Partial** (V10).
2. **Scale** by `(override ?? household) / servings_default`. Never scale
   `knivspids` or null quantities (V5).
3. **Key** each line by `ingredient id + unit family` (V1). Families: mass
   (`g`,`kg`), volume (`ml`,`dl`,`l`), and every other unit its own family.
   Null-unit counts (`3 løg`) are the `stk` family.
4. **Sum** within a key in the family's base unit (g, ml).
5. **One row per ingredient**: if an ingredient has more than one family, the
   row shows joined amounts (`300 g + 2 stk gulerødder`, V2). The row key is the
   ingredient id; the per-family parts carry their own keys for V1's
   "amount went up" check.
6. **Display unit** (V3) → **round** (V4) → **format** Danish (½ ¼ ¾, comma).
   Rounding happens *after* summing, so two half-onions make one onion.
7. **Name**: plural only if `pluralises` and quantity ≠ 1; `stk` hidden (V6).
8. **Aisle** from the ingredient; sort aisles by walking order, rows within an
   aisle by name.
9. **State**: carry `priorStates` by key; staples and lines that are optional in
   *every* source start `skipped`; a `bought` row whose amount rose returns to
   `to_buy` (V1, V8).
10. **Sources** for the `Fra {n} retter` line: recipe title + scaled amount per contributing line, plus `Tilføjet af dig` for merged hand-added items.
11. Merge `extraItems` that carry an ingredient into their rows (V20); append the rest under `ANDET`. Apply `quantityOverrides` where `base_amount` still matches (V22); `personalStaples` start skipped (V23).

**Guarantees, enforced by golden fixtures in `fixtures/build_list/`:**
determinism (same input → byte-identical output), order independence of
entries, idempotence (rebuilding with the output's states changes nothing), and
no line ever disappears (every input line is in exactly one row's sources).

**When it runs:** on `Byg sedlen`, on `Opdatér sedlen`, and automatically on
arrival from `Gem og tilføj` if nothing is checked off yet (amended V9). It
never runs silently while In-Store mode is open.

**Server parity (A3):** not built in v1. The list model is open to a later
SKU-mapping layer (ADR 0001): a row's ingredient id is the join key.

---

## 6. Local-first sync (ADR 0006, A5)

**Anonymous:** nothing syncs except content delta (§4). The phone is the only
copy.

**Signed in:** these record types sync, each independently:

| Record | Identity | Conflict rule |
|---|---|---|
| `household` | one per account | last write wins |
| `week_entry` | client UUID; natural key `(account, recipe)` | upsert; delete is idempotent (`204` either way); servings sent as absolute values |
| `item_state` | `(account, item_key)` | last `changed_at` wins (v2 `checked_at` rule) |
| `extra_item` | client UUID | last write wins; delete idempotent |
| user `recipe` + lines | server UUID | server-authoritative (created by import save; no edits in v1) |
| `local_ingredient` | server UUID | server-authoritative (curation can rewrite) |

- **Push:** the outbox sends absolute values, never deltas, each with an
  `Idempotency-Key`. Replays converge.
- **Pull:** `GET /api/v1/sync?since=<cursor>` returns every changed record and
  tombstone for the account, ordered by a server-issued monotonically
  increasing `version`; the cursor is the max version seen.
- **When:** on app foreground, after a local write (debounced), and on
  reconnect. Never blocks UI. In-Store mode writes locally; the outbox drains
  later.
- **Clock caveat:** `changed_at` is the phone's clock. Two phones with badly
  skewed clocks can resolve a check-off the wrong way. Accepted for v1
  (household sharing is out of scope, so this is one person with two phones).

**First sign-in** (ADR 0006): if the account's week is empty, upload the
phone's records. If both are non-empty, ask once ("Du har allerede en uge
gemt."); the losing side's week entries, item states, extra items and household
servings are discarded. No merge.

**Sign-out:** revoke the token server-side, then wipe all account records from
SQLite. **Account deletion:** server marks the account, revokes tokens, queues
the purge job; the phone deletes imports and local ingredients and keeps its
week as anonymous.

---

## 7. Import pipeline (ADR 0010–0013, 0015)

### 7.1 API

| Call | Who | Notes |
|---|---|---|
| `POST /api/v1/imports` `{url}` or `{text, title?}` | device token **or** account | `Idempotency-Key` required. Returns `{id, status}` immediately. |
| `GET /api/v1/imports/{id}` | same caller | Always a partial body: `status` = `queued` → `fetched` (stage 1: title, image URL, domain) → `parsed` (stage 2: lines) or `failed` + `error_code`. Includes the server's flag threshold. |
| `POST /api/v1/recipes` `{import_id, lines, servings, …}` | **account only** | Saves the reviewed draft as the user's recipe. `Idempotency-Key`. Duplicate URL for this account → returns the existing recipe (open point 2). |

The phone polls `GET /imports/{id}` (~500 ms, backing off) and drives the
12 s soften / 25 s paste-text UI from its own clock (ADR 0015).

### 7.2 Worker job (Procrastinate)

```
normalise URL ─▶ parse cache hit? ──yes──▶ copy facts into this import ─▶ parsed
      │no
      ▼
fetch (SSRF guard, 10 s, 3 MB cap, honest User-Agent)
      ▼
stage 1: JSON-LD Recipe / og: tags → title, image URL, servings, time ─▶ fetched
      ▼
lines:  JSON-LD recipeIngredient → Danish line parser (core rules)
        no markup → LLM over extracted page text (structured output, Danish prompt)
        pasted text → LLM directly
      ▼
resolve each line: exact → alias → pg_trgm fuzzy → unresolved (+≤5 suggestions)
      ▼
score: confidence_parts, min(), model self-score may only lower ─▶ parsed
      ▼
write parse cache (facts + image URL only, keyed by normalised URL)
```

- **Adapters** (ADR 0012): `UrlAdapter`, `TextAdapter`. Each yields the same
  intermediate (title?, image_url?, raw lines, meta); everything after is
  shared.
- **SSRF guard:** resolve DNS first and refuse private, loopback and
  link-local addresses; `http(s)` only; follow ≤3 redirects, re-checking each.
- **LLM:** Anthropic API, model and effort set in config. The parser spike
  picks the model against the golden set (candidates: Haiku 5.5, Sonnet 5.5,
  Opus 5.5). Input is page text or pasted text only — no user, device or
  account identifiers in the prompt or metadata.
- **Contract:** exactly ADR 0011 (+ `is_range` / `quantity_high`).

### 7.3 Abuse and cost controls (ADR 0006)

- Per-device-token daily parse count (~5) and per-account daily count
  (~20), stored in Postgres. Cache hits don't count.
- **Global daily spend ledger:** each LLM call records its token cost; when
  the day's total passes the cap, new non-cached imports fail fast with
  `import_paused` (screen D-6b). A config flag pauses imports manually.
- Device tokens are issued by `POST /api/v1/auth/device` and can be revoked.
  App Attest / Play Integrity is **not** in v1; revisit if abuse appears.

### 7.4 Ingredient resolution (A10)

Server-side only, at import time: `normalise()` the parsed name → exact match
on canonical names → exact match on aliases → `pg_trgm` similarity over names
and aliases (threshold in config) → otherwise `unresolved` with the top-5
trigram matches as `suggested_ingredients`. The LLM may *propose* a canonical
id on its path; it is accepted only if it exists and is scored `fuzzy` until a
human confirms it.

---

## 8. Accounts and auth (ADR 0005, 0006, A6)

| Endpoint | Purpose |
|---|---|
| `POST /auth/device` | issue an anonymous device token (parse-only scope) |
| `POST /auth/code` `{email}` | send a 6-digit code (rate-limited per email and per device; always `202`, never reveals whether the email exists) |
| `POST /auth/verify` `{email, code}` | create the account if new; return a session token |
| `POST /auth/logout` | revoke the session token |
| `DELETE /account` | mark for deletion, revoke tokens, queue purge (≤30 days) |

- Codes: 6 digits, 10-minute expiry, 5 attempts, stored hashed.
- Session tokens: opaque random, stored hashed, **90-day sliding expiry**. No
  refresh-token dance.
- App Review access: a configured review email whose code is fixed in
  staging/production settings, audited.

---

## 9. Telemetry and privacy (ADR 0017)

- **Sentry (EU)** in app and server. `sendDefaultPii` off; no user id; request
  bodies, emails and tokens scrubbed.
- **Counts:** `POST /api/v1/events` with `{event, value?, app_version}` from a
  fixed enum. The server increments daily aggregates and does not store the
  raw request or the IP (configured at the Django logging layer and checked in
  Render's request logs settings). No device id.
- Legal check before release is a milestone in the epic map.

---

## 10. Data the server holds, per person

| Data | Why | Deleted by |
|---|---|---|
| email | sign-in | purge job |
| week, item states, extra items, household servings | sync | purge job |
| imported recipes + lines + `raw_source_text` | the user's imports | purge job |
| local ingredients | the user's imports | purge job (promoted/mapped canonical rows stay, they're editorial content) |
| device tokens + parse counts | abuse control | expire after 30 days unused |
| parse cache (facts + image URL per normalised URL) | cost | not personal; kept |

---

## 11. Hosting and operations (ADR 0007, 0009, A7–A9)

`render.yaml` blueprint, region **frankfurt**, instantiated twice
(`staging`, `production`):

| Service | Type | Notes |
|---|---|---|
| `umami-api` | web service | Django + gunicorn; runs migrations as a pre-deploy command |
| `umami-worker` | background worker | `manage.py procrastinate worker`; also runs **periodic tasks** (purge, code cleanup, device-token expiry, daily spend reset) |
| `umami-db` | Render Postgres, paid tier | PITR; **direct internal connection** (port 5432). Render's PgBouncer is opt-in and transaction-mode, which breaks `LISTEN/NOTIFY`, so it stays off. Extensions: `pg_trgm`. |
| `umami-images` | static site | curated images, hashed filenames |

- **Email: Brevo** (EU-hosted, French company). Postmark keeps its data in the
  US and has no EU region, so it fails ADR 0009. Sign Brevo's DPA and review its
  subprocessor list. *This amends ADR 0009.*
- **Source and CI: GitHub + GitHub Actions** (decided 12 Nov 2026). Remote:
  `github.com/asgersoerensen/umamo-v3` (added 12 Nov 2026; nothing pushed
  yet). Workflows:
  - **on every PR:** TypeScript checks + `packages/core` tests, Django tests
    (against a Postgres service container with `pg_trgm`), both suites run
    every file in `fixtures/`, regenerate the OpenAPI client and fail on drift,
    lint;
  - **on main:** the same, then `export_bundle` → EAS Build for **iOS and
    Android** (ADR 0008), and Render deploys `staging` from main via its GitHub
    integration;
  - **production:** a manual promotion (tag or workflow dispatch), not on every
    merge.
  - Secrets: `EXPO_TOKEN` in GitHub Actions secrets; Render and Anthropic keys
    stay in Render, never in GitHub.
- **Secrets:** Render environment groups per environment; EAS secrets for the
  app. The Anthropic key lives only on the worker.

---

## 12. Check against spec §10 (Not in v1)

| §10 item | How this architecture avoids designing for it |
|---|---|
| Day-of-week, calendar | `week_entry` has no day field. |
| Pantry inventory | No inventory table; staples are an ingredient flag. |
| Household sharing | One account = one person; sync conflict rules assume one person, not concurrent editors. |
| Nutrition | No nutrition fields on ingredients. |
| Price comparison / SKU / catalog / prices | No price or product tables. The ingredient id is a join key a later mapping table could use, and that's all. |
| Photo/OCR, video import | Adapter interface exists (two implementations); no OCR or video code. |
| Cooking mode | `method_steps` displayed only; no step state, timers or keep-awake outside In-Store. |
| Multiple weeks / history / favourites | One open-ended set of week entries; no week table with dates. |
| Recipe editing after import | No `PATCH /recipes`; delete + re-import. |
| Store-specific aisle order | Aisle order is a constant in `packages/core`. |
| Social features; social login; passwords | Email code only. |
| Push notifications | No push tokens collected. |
| Dark mode | Design tokens light-only (structure allows a theme later). |
| Localisation | One `da.ts`; no i18n framework. |
| Basket handoff / grocery integration | Share sheet text only. |
| Payments, paywall | No entitlement checks anywhere. |
| Browser extension, web client | No web build target; API has no cookie auth or CORS for browsers. |
| Meal types | No meal-type field. |
| Week rollover | No `week_start_date`. |
| `Grupper efter opskrift`, `Gem som note` | Not in the list builder's output modes. |
| Third-party analytics | Counts go only to our API. |
| Storing method text / copying images from imports | Pipeline extracts no method text; stores image URL only. |

---

## 13. Risks and open items

| Risk | Mitigation / owner |
|---|---|
| **0/44 curated hero images** (licensing) | Ship blocker for the first slice. Content epic: commission or license, or photograph. |
| Parser quality on markup-free pages | Parser spike first; screens build against fixtures meanwhile. |
| LLM cost from anonymous parsing | Per-device and global caps; parse cache; kill switch. |
| Share-extension complexity in Expo | Mobile epic spike; the in-app `Importér` path doesn't depend on it. |
| Client clock skew in LWW | Accepted for v1 (single person, §6). |
| ePrivacy reading of anonymous counts | Legal check milestone before release. |
| Render Frankfurt: external DB access reported restricted | Only matters for local admin tooling; use Render shell or a one-off job. Verify at setup. |
