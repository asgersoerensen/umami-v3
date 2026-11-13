# Design

Two sources, one rule each (ADR 0020). The spec (`docs/product/spec.md`) wins any conflict.

| What | Where |
|---|---|
| How it **looks**: tokens, components, static screens | Penpot file **"Umami"** (file id `51f2d744-23b9-8138-8008-f08eee9dd64f`; pages: Tokens, Components, Screens 390, Screens 320 XL, Assistant). Token set `umami/core`: 20 colours, 10 font sizes, weights, spacing, radii, sizing; 12 library typographies (Inter as a stand-in for the platform font). |
| How it **behaves**: flows, states, the live list builder | `ui-draft/index.html` — open in a browser; review copy at https://app.superset.sh/page/umami-v1-ui-draft-12o0i5 |
| Exported tokens | `tokens/` (generated from Penpot; never hand-edited) |
| Screen PNGs at milestones | `screens/` |
