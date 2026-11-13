# 0002 — The grocery list is built on the device

- **Status:** Accepted · 12 Nov 2026
- **Conflict resolved:** spec-internal (§5 vs §8)

## Context

Spec §8 says import is the *only* network-required flow, and the bundled
recipes mean the picker never needs a network. But §5 has an
"Offline (no list yet)" state and a 3 s build timeout, which only make sense if
the list is built on a server. umami-v2 materialised the list server-side.

The bar is "a cold parent has a finished list in under three minutes,
one-handed" — and the shop has no signal.

## Decision

- The list is built **on the device** by one **pure, deterministic TypeScript
  function**: `(week, recipes, ingredients, prior item states) → list`. No I/O,
  no clock reads, no randomness.
- The server may hold a parity implementation (for sync validation, a future
  web client or support tooling). If it exists, client and server share
  **golden-file fixtures** (input JSON → expected list JSON) and both run them in
  CI. Parity is optional for v1; the fixtures are not.
- When signed in, the *week and item states* sync. The list itself is derived
  and is rebuilt locally; it is not a synced document.

## Consequences

- Every ingredient a list needs must be on the device: curated recipes and the
  canonical ingredient table ship in the bundle, refreshed by delta sync; a
  signed-in user's imports and local ingredients sync down.
- A phone that is missing recipe data for a week entry (e.g. freshly signed in,
  imports not yet downloaded) builds the list without that entry and shows
  **Partial** (ADR 0018 V10).
- The function is the single most-tested unit in the codebase.

## Spec impact (rev 4, §5)

- Delete the **Offline (no list yet)** state and its strings.
- Delete "Max 3s before falling back to error" from the loading state.
- Full-screen error only when the build function throws and no earlier list
  exists.
- `Opdatér sedlen` works offline — remove the "Kræver forbindelse." subtext.
- **Partial** is redefined (0018 V10).
