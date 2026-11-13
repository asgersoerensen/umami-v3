# 0008 — Expo, cross-platform code, iOS released first, no web

- **Status:** Accepted · 12 Nov 2026
- **Conflict resolved:** business plan (Next.js web MVP) vs spec (native app:
  share sheet, in-store mode, screen-awake, haptics).

## Decision

- Client is **Expo (React Native, TypeScript)**.
- The codebase is **cross-platform from day one**: no iOS-only APIs without an
  Android path, and CI builds both platforms on every main-branch build.
- **Release iOS first.** Android follows once in-store mode has been tested on a
  mid-range Android phone (performance, keep-awake, back-button behaviour).
- **No web client** in v1.
- OTA updates via **EAS Update** with its default servers (ADR 0009).

## Consequences

- One codebase; the Android launch is a QA-and-store task, not a port.
- The OS share-sheet *import* entry point (spec §7) needs a share extension on
  iOS and an intent filter on Android — both are native config inside Expo
  (config plugin / dev build), not Expo Go. Flagged for the mobile epic.
- `da.ts` single strings file (spec §12) stays.

## Spec impact (rev 4)

§10 gains "Web client". Header notes iOS-first release.
