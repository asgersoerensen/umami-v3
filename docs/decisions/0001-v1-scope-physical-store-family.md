# 0001 — v1 serves families shopping in physical stores

- **Status:** Accepted · 12 Nov 2026
- **Conflict resolved:** `business-context.md` (March) vs `spec.md` rev 3

## Context

The March business plan describes a different product: Nemlig cart auto-fill,
SKU matching against a grocery catalog, a browser extension, freemium at
99 DKK/month, meal types (breakfast/lunch/dinner) and a Next.js web MVP. Spec
rev 3 (Sept) describes a dinner-only native app whose handoff is a share sheet
plus in-store check-off, and records that third-party basket integration was
declined (UMA-15: no public Nemlig API, `robots.txt` + Queue-it).

## Decision

- The v1 persona is **a Danish family that shops in a physical store**. This is
  also the durable base method; later features extend it, they don't replace it.
- **Online cart / basket handoff is a later feature addition** — parked, not
  killed. No online-shopper share format in v1.
- **Freemium and pricing are parked.** No payments code, no paywall, no
  entitlement checks in v1.
- **Dinner only.** No meal types.

## Consequences

- No grocery catalog, SKU table or price data in v1. The list model stays open
  to a later SKU-mapping layer: a list item is keyed by ingredient + unit
  family (ADR 0018 V1), which is the natural join key for a future mapping
  table. Nothing in v1 should assume list items are strings.
- The business plan's stack (BullMQ/Redis, Next.js, Vercel/Supabase,
  email+password) is not inherited — see 0005, 0007, 0008, 0009.
- The business plan's legal stance on not republishing source text/photos *is*
  inherited — see 0010.

## Spec impact (rev 4)

§10 gains: payments / subscriptions / paywall; SKU matching / grocery catalog;
browser extension; meal types (dinner only); online-shopper share format.
