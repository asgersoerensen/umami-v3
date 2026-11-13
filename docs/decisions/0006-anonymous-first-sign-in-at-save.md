# 0006 — Anonymous first; imports save on the phone without an account

- **Status:** Accepted · 12 Nov 2026 (option b, amended by R1 = b)
- **Amended 12 Nov 2026:** signed-in parse limit; draft lifetime (import design §10, points 3–5).
- **Amended 13 Nov 2026 (UI-draft review):** sign-in is no longer required at
  `Gem`. Anonymous imports are saved on the phone and upload on first sign-in.
  Supersedes the "required at `Gem`" and "always account-owned" rules below
  (struck through). Spec rev 5 carries this into §1, §7, §8 and §12.
- **Gap resolved:** the spec defers sign-in but doesn't say what moves to the
  account, what happens on conflict, sign-out, account deletion, or who may call
  the LLM.

## Decision

**Anonymous core loop.** Pick → plan → list → in-store needs no account and no
network. Onboarding never asks for an account.

**Import (R1).**
- **Parsing is allowed anonymously** under a **device token** issued on first
  launch or first import. The token authorises *parse only*.
- Limits: ~**5 parses per day per device** plus a **global daily LLM spend cap**.
  **Signed-in accounts get a higher limit** (initially **20 parses per day per
  account**); the anonymous limit screen offers `Log ind for at importere
  flere`. Cached parses (ADR 0010) count against neither limit. Exact numbers
  are config.
- ~~Sign-in is required at `Gem`~~ → **`Gem` works without an account.** The
  recipe, its lines and any new local ingredients are saved **on the phone**.
  An unsaved review draft is still kept locally: the most recent draft only,
  for **7 days**, surviving restarts; reopening `Importér` offers to continue it.
- **Duplicate at save:** if the phone (or, signed in, the account) already has
  this URL, the draft is discarded and the existing recipe opens (added to the
  week if `Gem og tilføj` was pressed).
- ~~Saved imports are always account-owned.~~ → **Anonymous imports and local
  ingredients live on the phone only** until first sign-in. They are not backed
  up: deleting the app loses them. The server holds only the parse cache
  (facts, keyed by URL, ADR 0010), never an anonymous saved recipe.

**Prompts.**
- ~~Required: at `Gem` on an import.~~ No required prompt anywhere.
- Optional: once, after the first "Så er der købt ind", on returning to List —
  with `Ikke nu`, which silences it.
- **Never** in in-store mode, never before a share, never in onboarding.
- `⚙ → Log ind` is always available.

**First sign-in on a device.** Upload the local week, item states, household
servings, **and any anonymous imports and local ingredients** (each with an
`Idempotency-Key`; an import whose URL the account already has is dropped and
its week entry points at the account's copy). If **both** the device and the account have a non-empty week, ask
once: "Du har allerede en uge gemt." → `Brug den gemte ({n})` /
`Behold denne telefons ({n})`. Household servings follow the chosen week. No
merging of weeks.

**Sign-out.** Confirm, then wipe account data from the device (week, item
states, imports, local ingredients). The device returns to an empty anonymous
state.

**Account deletion.** In-app `⚙ → Slet konto` (App Store 5.1.1(v); GDPR
erasure). Confirm, then the account is hard-deleted within **30 days** by a
queued purge job (ADR 0007). The device keeps its *local* week and becomes
anonymous; imported recipes are removed from the device.

## Consequences

- The LLM endpoint is reachable without an account → abuse controls are a
  launch requirement, not a nice-to-have.
- Imports become part of the first-sign-in upload, so `byb.5` grows; anonymous
  imported recipes need an on-device store (E-LOCAL) before they need a server.
- Sync is only for signed-in users. It reuses v2's replay-safety rules: writes
  send absolute values, never deltas; item states resolve last-`checked_at`-wins;
  `Idempotency-Key` on import save.
- Merge-on-conflict is deliberately avoided: one question, two answers.

## Spec impact (rev 4)

§1 unchanged (no account in onboarding). §4 ⚙ menu: `Log ind` / `Log ud`,
`Slet konto`. §7: ~~sign-in at `Gem`~~ no sign-in in import (rev 5). §8 sign-in row rewritten. §12: new `auth.*`
strings.
