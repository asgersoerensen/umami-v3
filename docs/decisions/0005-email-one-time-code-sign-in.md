# 0005 — Email + 6-digit one-time code is the only sign-in

- **Status:** Accepted · 12 Nov 2026
- **Conflict resolved:** business plan (email + password) vs spec (method
  unspecified; "no social").

## Decision

- Sign-in is **email + a 6-digit one-time code**. No passwords, no magic links.
- **Sign-up = sign-in**: an unknown email creates the account when the code is
  verified.
- Codes are single-use, short-lived (proposal: 10 min), rate-limited per email
  and per device, and stored hashed. Exact limits are a backend-epic detail.
- Code emails go out through an **EU transactional email provider** (ADR 0009)
  via the task queue with retries (ADR 0007).
- **Sign in with Apple** is a v1.1 candidate, not v1. Note that if *any*
  third-party login is added on iOS later, App Store guideline 4.8 applies.
- The spec's "no social" (§10) means **social features**, not social login.

## Consequences

- No password reset, no password storage, no breach surface for credentials.
- Deliverability matters: a code that lands in spam blocks the user. The
  provider choice (Postmark EU vs Brevo) is made in the architecture overview.
- Review accounts: App Review needs a way in. Plan a fixed review email whose
  code is readable by the team (backend-epic task).

## Spec impact (rev 4)

§8 sign-in row names the method. §10 clarifies "no social" and lists SIWA as a
v1.1 candidate. §12 gains `auth.*` strings for email/code entry.
