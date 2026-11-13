# 0017 — Sentry EU + first-party anonymous counts; legal check before release

- **Status:** Accepted · 12 Nov 2026 — **legal check required before release**
- **Gap resolved:** the spec's bar ("a finished list in under three minutes")
  has no way to be measured, and nothing covers consent.

## Decision

- **Crash/error monitoring:** Sentry, EU region. No user IDs, no emails, no
  personal data in events or breadcrumbs; scrub request bodies.
- **Product counts:** a small, **enumerated** set of anonymous events sent to
  **our own API**:
  - no device ID or install ID, no account ID;
  - IP addresses are not stored;
  - the server aggregates (counts / histograms) and discards raw events.
  - Example events: time from cold open to first list built; in-store mode
    completed; import started / saved / abandoned; `Overrask mig` used.
- **No third-party analytics SDK** and **no consent screen** in v1.
- **Legal check before release:** ePrivacy / the Danish
  *cookiebekendtgørelse* covers apps reading from or writing to the device; we
  believe this setup needs no consent, but that is a grey area and must be
  confirmed.
- A **usability test with 5–10 Danish families** is a milestone before launch —
  the three-minute bar is measured there, not in telemetry.

## Spec impact (rev 4)

§10 gains "Third-party product analytics". §8 gains a *Privacy* row.
