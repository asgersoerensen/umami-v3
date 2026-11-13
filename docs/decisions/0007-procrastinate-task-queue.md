# 0007 — Procrastinate (Postgres-backed) task queue

- **Status:** Accepted · 12 Nov 2026
- **Conflict resolved:** business plan (BullMQ — a Node/Redis library, wrong
  ecosystem for Django) vs v2 (Celery + Redis, off by default, thread mode).

## Decision

- Use **Procrastinate** on the existing Postgres. No Redis, no broker to run.
- Wrap it behind a small app interface — `start_import(...)`,
  `get_import_status(...)` and equivalents — so the queue is swappable.
- v1 jobs:
  1. **Import parse** — two-stage (stage 1 meta, stage 2 lines; ADR 0013), no
     hard timeout on the job (the UI softens at 12 s and offers paste-text at
     25 s; ADR 0015).
  2. **Account purge** — hard delete ≤30 days after `Slet konto` (ADR 0006).
  3. **One-time-code cleanup** — expire and delete old codes.
  4. **Code email send** — with retry and backoff (ADR 0005).
- Periodic jobs run via Procrastinate's periodic tasks or a Render cron
  (decided in the architecture overview).

## Consequences

- Requires a **direct Postgres connection** that supports `LISTEN/NOTIFY`
  (not a transaction-mode pooler). To be verified for Render managed Postgres in
  the architecture overview.
- One datastore to back up and restore.
- Throughput ceiling is far above v1 needs; revisit only if imports exceed
  hundreds per minute.
