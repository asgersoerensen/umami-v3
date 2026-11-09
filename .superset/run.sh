#!/usr/bin/env bash
# Paradev Run button: start the dev server on this workspace's reserved port.
set -euo pipefail
cd "${SUPERSET_WORKSPACE_PATH:-$(git rev-parse --show-toplevel)}"
. .superset/lib/common.sh
. .superset/lib/ports.sh

# Re-reserve if setup never ran here (idempotent: keeps an existing reservation).
load_ports || reserve_ports
load_ports

if port_in_use "$APP_PORT"; then
  echo "Port $APP_PORT is already in use (dev server already running?)." >&2
  lsof -nP -iTCP:"$APP_PORT" -sTCP:LISTEN >&2 || true
  exit 1
fi

# Make sure backing services are up (cheap no-op if already running).
if cf="$(compose_file)" && command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  docker compose -f "$cf" -p "$COMPOSE_PROJECT_NAME" up -d --wait
fi

log "Starting dev server on http://localhost:$APP_PORT"
if [ -f manage.py ]; then
  exec uv run python manage.py runserver "0.0.0.0:$APP_PORT"
elif [ -f package.json ]; then
  # Next.js / Vite both accept --port; PORT is also exported.
  if   [ -f pnpm-lock.yaml ]; then exec pnpm dev --port "$APP_PORT"
  elif [ -f bun.lock ] || [ -f bun.lockb ]; then exec bun run dev --port "$APP_PORT"
  elif [ -f yarn.lock ]; then exec yarn dev --port "$APP_PORT"
  else exec npm run dev -- --port "$APP_PORT"
  fi
else
  echo "No dev server found yet (no manage.py or package.json). Nothing to run." >&2
  exit 1
fi
