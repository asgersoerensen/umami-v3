# Umami

A Danish meal-planning app: pick a week of dinners, get one consolidated
grocery list in walking order, and tick it off one-handed in the shop.

**The bar:** a parent opens the app cold and has a finished grocery list in
under three minutes, one-handed.

## Status

Pre-code. Decisions, architecture and the epic map are settled (work is in
beads: `bd ready`); the UI draft is in review.

## Where things are

| Path | What |
|---|---|
| `docs/product/spec.md` | Product spec — **the source of truth** for behaviour |
| `docs/product/import-review-design.md` | Import + review screens (buildable design) |
| `docs/product/business-context.md` | March business plan — background only; loses every conflict |
| `docs/decisions/` | Architecture & product decisions (ADRs) |
| `docs/architecture/overview.md` | System architecture (approved) |
| `design/ui-draft/index.html` | Clickable UI draft for scoping review |

## Stack (decided)

- **App:** Expo / React Native (TypeScript). iOS first, Android follows, no web.
- **API:** Django + Postgres; Procrastinate for background jobs.
- **Hosting:** Render, Frankfurt.
- **Sign-in:** email + 6-digit one-time code.

See `docs/decisions/README.md` for the reasoning.

## Work tracking

Issues live in **beads** (`bd`). Run `bd ready` for available work and
`bd prime` for the workflow. See `CLAUDE.md`.

## Prior art

`umami-v2` (local, not a remote) built against the same spec. It is prior art,
not a base: see ADR 0016 for what is reused.
