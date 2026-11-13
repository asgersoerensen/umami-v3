# 0019 — Stretch: an AI assistant that builds the week and the list by chat

- **Status:** Proposed · 13 Nov 2026 (owner asked for it as a stretch feature
  after approving UI draft 4 as v1)
- **Revised 13 Nov 2026:** the assistant reads the household profile through
  tools so the user never repeats themselves (owner request). Adds a
  household profile with food preferences (§6a).
- **Scope:** **Not part of v1.** Own milestone (M5) after the iOS release. Ships
  behind a server-side feature flag; v1 must not wait for it or depend on it.

## What it is

A chat where a family member can say, in Danish, what they want, and the
assistant fills the week and the list:

> "Fem hurtige retter til næste uge, børnevenlige, ingen svinekød. Torsdag er
> vi seks."
> "Vi har ris og løg nok — og sæt bleer på."

## Decision (proposed)

**1. The assistant drives the same actions as the UI. It never computes the
list.** It works through tools that map one-to-one to existing domain
actions: search recipes, add / remove / swap a meal, set household or per-meal
servings, add a list item (through the same `[qty] [unit] name` parser and
ingredient match as `Tilføj en vare`), skip on this list (*Spring over*) or make a personal staple (*Basisvare*),
clear checks. The grocery list is still built by the deterministic on-device
builder (ADR 0002, 0003). The LLM never produces quantities, never merges
lines, never invents ingredients.

**2. Only real recipes.** It picks from the curated slate and the user's own
imported recipes. Generating new recipes, and importing a URL from chat, are
out of scope (separate later decision: generated recipes raise quality and
liability questions the curated slate avoids).

**3. Proposals, not silent edits.** Each turn that changes something returns a
**proposal card** (for example "5 retter · til 4, torsdag til 6" with the five
cards) and `Tilføj til ugen` / `Ikke de her`. Applying runs the normal actions
and shows the usual `Fortryd` toast. Week-changing proposals follow the stale
rules (V9): if anything on the list is already ticked, the list is not rebuilt
behind the user's back.

**4. Where it lives.** Not a fourth tab. A `Spørg` button in the Opskrifter
header and on the empty Plan state opens a full-screen chat sheet. The
three-minute tap path stays the primary path.

**5. Signed-in only, with limits.** The assistant needs an account (cost and
abuse; anonymous parsing already uses the anonymous budget). Per-account daily
turn limit (start: 30 turns/day, config), same global spend ledger and kill
switch as import (overview §7). Offline: the button is shown dimmed with
`Kræver forbindelse`.

**6. Architecture.** `POST /api/assistant/turn` on the Django web service,
streamed (SSE). The client sends only the recent messages (last ~20). Before a
turn the client flushes its sync outbox, so the server's copy of the account is
current. **Read tools run on the server** against the account's synced data;
**mutating tools are returned to the client as a proposal** and applied there.

**6a. The assistant knows the household — through tools, not repetition.**
Read tools (server-side, scoped to the signed-in account, nothing else):

| Tool | Returns |
|---|---|
| `get_household` | household size, per-meal overrides in the current week |
| `get_preferences` | diets (e.g. vegetar on weekdays), ingredients to avoid, disliked dishes, kid-friendly default, max cooking time on weekdays, liked cuisines |
| `get_personal_staples` | Mine basisvarer |
| `get_week` | meals in the current week with servings |
| `get_list` | list rows: name, amount, state (to_buy / bought / skipped) |
| `get_my_recipes` | the user's imported recipes (titles, ids, tags) |
| `search_recipes` | curated + own recipes by text, filters, time, cost, cuisine, excluding avoided ingredients |

The system prompt tells the model to call `get_household` and
`get_preferences` before proposing meals, and never to ask for something a
tool can answer. `search_recipes` applies "avoid" ingredients as a **hard
filter in SQL**, not as a model instruction — an avoided ingredient can't slip
through on a bad turn.

**Remembering new preferences** is a proposal too: when the user says "vi
spiser ikke svinekød", the assistant offers a card `Skal jeg huske det?` →
`Husk det` / `Kun denne gang`. Nothing is written to the profile without that
tap. Everything is visible and editable under `⚙ → Det spiser vi`.

**The household profile is new.** v1 has only household size and personal
staples. This adds `household_preferences` (one row per account: diets,
avoid-ingredient ids, disliked recipe ids, kid-friendly default, weekday time
cap, liked cuisines), synced like household servings, included in data export
and account deletion. Avoid-ingredients are stored as plain "undgå" ingredient
ids with **no reason recorded** (we never store "allergy"), which keeps health
data out of the profile itself — the chat text can still contain it (see the
privacy conflict below). Whether the Opskrifter tab also honours the profile
(e.g. hide avoided ingredients by default) is an open question. No conversation is stored on the
server; the phone keeps the current conversation until `Ryd ugen` or 7 days.
Model and effort are config, chosen by an eval set (below), like the parser.

**7. Evaluation before launch.** A golden set of Danish conversations
(constraints, servings changes, staples, ambiguous asks, refusals of
out-of-scope requests) with assertions on the tool calls, run in CI against a
recorded transcript and nightly against the live model.

## The conflict this creates — needs an owner decision

ADR 0009 says **"the LLM never receives personal data."** Chat text breaks
that. People will type names, guests, and above all **allergies and diets**,
which can be health data (GDPR art. 9). Options:

- **(a) EU-hosted model endpoint** — run the same Claude models through an EU
  cloud region (for example AWS Bedrock in Frankfurt) under that provider's
  DPA. Keeps ADR 0009's "EU processors only". Recommended.
- **(b) Anthropic API directly** with a DPA and an international-transfer
  basis. Simpler, one provider for import and assistant; needs the legal check
  to accept a non-EU processor for chat content.
- **(c) Strip before sending** — client-side redaction of names/emails. Doesn't
  catch allergies; not sufficient alone.

Whatever is chosen: no chat content in logs, Sentry or telemetry (only counts:
turns, proposals shown/applied); a one-line notice in the chat sheet; the
legal check (ADR 0017, bead `15a.3`) is extended to cover it.

## Consequences

- ADR 0009 gets an amendment once (a)/(b) is chosen.
- `packages/core` must expose the domain actions as a typed, serialisable
  action set (useful anyway for undo and tests); the tool schemas are generated
  from it so UI and assistant can't drift.
- A new spec section (§13, stretch) and §12 strings when it's accepted.
- Ongoing cost per active user, unlike import's mostly cached parses.

## Open questions

1. Privacy route (a)/(b) above.
2. Should a proposal be able to *both* change the week and add list items in
   one card, or one kind per card?
3. Does the Opskrifter tab also apply the profile (hide avoided ingredients,
   pre-select time cap), or is the profile assistant-only at first?
4. "Not the same as last week" needs meal history; v1 keeps one open-ended
   week and no history. Store the last few weeks' recipe ids, or skip?
5. Is "signed-in only" right, or should anonymous users get a small taste
   (e.g. 3 turns) as a sign-in reason?
