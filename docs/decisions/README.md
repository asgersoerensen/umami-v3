# Architecture & product decisions

One file per decision. ADR number = decision ID from the 12 Nov 2026 kickoff
session (D1–D18). The anonymous-import amendment (R1) is folded into ADR 0006.

**Precedence.** `docs/product/spec.md` is the source of truth for product
behaviour. Where an ADR changes the spec, the change is listed under *Spec
impact*; all of those landed in spec rev 4 (12 Nov 2026). Where an ADR and the
spec ever disagree, raise it — don't pick silently. `business-context.md` (March) is
background only and loses every conflict.

**Status values:** Proposed · Accepted · Superseded by NNNN.

| # | Decision | Status |
|---|---|---|
| [0001](0001-v1-scope-physical-store-family.md) | v1 serves families shopping in physical stores; online basket, SKU matching and pricing are parked | Accepted |
| [0002](0002-grocery-list-built-on-device.md) | The grocery list is built on the device by a pure function | Accepted |
| [0003](0003-deterministic-consolidation-and-local-ingredients.md) | Consolidation is deterministic; unknown ingredients become account-owned local ingredients | Accepted |
| [0004](0004-week-lifecycle-and-soft-cap.md) | One open-ended week, `Ryd ugen`, soft cap 7 | Accepted |
| [0005](0005-email-one-time-code-sign-in.md) | Email + 6-digit one-time code is the only sign-in | Accepted |
| [0006](0006-anonymous-first-sign-in-at-save.md) | Anonymous-first; import and save without an account (amended 13 Nov); migration, sign-out, deletion | Accepted |
| [0007](0007-procrastinate-task-queue.md) | Procrastinate (Postgres-backed) task queue | Accepted |
| [0008](0008-expo-cross-platform-ios-first.md) | Expo, cross-platform code, iOS released first, no web | Accepted |
| [0009](0009-render-frankfurt-hosting.md) | Render, Frankfurt; EU processors only | Accepted |
| [0010](0010-imported-recipe-content-storage.md) | Imports store facts, a link back and an image URL — no method text, no image copy | Accepted |
| [0011](0011-import-line-contract.md) | Import line contract (v2 format, verbatim) | Accepted |
| [0012](0012-input-adapters-one-contract.md) | One line contract, many input adapters | Accepted |
| [0013](0013-no-reflow-and-two-stage-import-skeleton.md) | No-reflow picker is a hard test; import skeleton is two-stage | Accepted |
| [0014](0014-time-band-derived-on-the-fly.md) | `time_band` is never stored; bands ≤20 / 21–30 / 31+ | Accepted |
| [0015](0015-import-review-design-ported.md) | Port v2's import review design into v3 | Accepted |
| [0016](0016-v2-as-prior-art.md) | umami-v2 is prior art; v3 is a fresh build | Accepted |
| [0017](0017-telemetry-and-privacy.md) | Sentry EU + first-party anonymous counts; legal check before release | Accepted |
| [0018](0018-defaults-for-spec-gaps.md) | Defaults for behaviour the spec leaves open (V1–V19) | Accepted |
| [0019](0019-ai-assistant-stretch.md) | Stretch (post-v1): AI assistant that builds the week and list by chat, through the same actions | Proposed |
| [0020](0020-design-sources-penpot-and-prototype.md) | Penpot owns visual design and tokens; the HTML prototype owns behaviour; spec wins | Accepted |
