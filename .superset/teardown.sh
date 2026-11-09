#!/usr/bin/env bash
# Paradev workspace teardown: stop everything setup.sh/run.sh started and release ports.
set -uo pipefail
cd "${SUPERSET_WORKSPACE_PATH:-$(git rev-parse --show-toplevel)}"
. .superset/lib/common.sh
. .superset/lib/ports.sh

load_ports || true

# Stop a dev server left running from the Run pane (anything listening on our ports).
for p in ${APP_PORT:-} ${WEB_PORT:-}; do
  pids="$(lsof -nP -tiTCP:"$p" -sTCP:LISTEN 2>/dev/null || true)"
  if [ -n "$pids" ]; then
    log "stopping process(es) on :$p ($pids)"
    kill $pids 2>/dev/null || true
  fi
done

# Remove this workspace's containers and volumes.
if cf="$(compose_file)" && command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  log "docker compose down ($COMPOSE_PROJECT_NAME)"
  docker compose -f "$cf" -p "$COMPOSE_PROJECT_NAME" down -v --remove-orphans || true
fi

release_ports
log "Teardown complete."
exit 0
