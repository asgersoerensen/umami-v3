# 0009 — Render, Frankfurt; EU processors only

- **Status:** Accepted · 12 Nov 2026
- **Amended 12 Nov 2026:** email provider fixed to Brevo (overview A7).
- **Conflict resolved:** business plan (Vercel + Supabase) vs v2 (Fly.io,
  `iad` = US East). Gap: no data-residency decision for a Danish consumer app.

## Decision

- Host on **Render, Frankfurt region**, declared in `render.yaml`:
  - web service (Django),
  - background worker (Procrastinate),
  - cron (if periodic jobs aren't run by the worker),
  - managed Postgres (paid tier with point-in-time recovery), reached over a
    direct connection.
- **EU processors only** for personal data:
  - transactional email: **Brevo** (EU-hosted). Postmark has no EU data
    region, so it is out (architecture overview A7);
  - error monitoring: Sentry, EU region (ADR 0017).
- **The LLM never receives personal data.** It sees page HTML or pasted recipe
  text only — no email, no account ID, no device ID.
- EAS Update default servers (code bundles, no personal data).
- v2's Fly configuration is not reused.

## Consequences

- One provider for app, worker and database; secrets in Render env groups.
- Verify before relying on it: Render managed Postgres supports `LISTEN/NOTIFY`
  on direct connections (needed by ADR 0007).
- A data-processing agreement is needed with each processor that touches
  personal data (Render, email provider, Sentry).
